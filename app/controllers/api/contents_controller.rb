class Api::ContentsController < Api::ApiController
  before_filter :set_events_param

  def index
    if params[:max_results].present? 
      @contents = Content.limit(params[:max_results])
    else
      @contents = Content
    end

    if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
      sort_order = params[:sort_order]
    end

    if params[:repository].present? and @contents.present?
      @contents = @contents.includes(:repositories).where(repositories: {dsp_endpoint: params[:repository]}) 
    end
    
    if params[:events]
      @contents = @contents.events
      sort_order ||= "ASC"
      @contents = @contents.order("start_date #{sort_order}")

      # limit query so we're not accidentally rendering thousands of json objects
      @contents = Content.limit(500) unless params[:max_results].present?

      if params[:start_date].present?
        start_date = Chronic.parse(params[:start_date])
        @contents = @contents.where('start_date >= ?', start_date)
      end
      if params[:end_date].present?
        end_date = Chronic.parse(params[:end_date]).end_of_day
        if end_date == start_date
          end_date = start_date.end_of_day
        end
        @contents = @contents.where('start_date <= ?', end_date)
      end
      if params[:event_type].present?
        @contents = @contents.where(event_type: params[:event_type])
      end

      # don't return featured events unless they're requested
      unless params[:request_featured].present?
        @contents = @contents.where(featured: false)
      end
      @contents = @contents.includes(:business_location, :images, :import_location)
    else
      sort_order ||= "DESC"
      @contents = @contents.order("pubdate #{sort_order}")
      if params[:publications].present?
        allowed_pubs = Publication.where(name: params[:publications])
        @contents = @contents.where(source_id: allowed_pubs)
      end
      if params[:categories].present?
        allowed_cats = ContentCategory.find_with_children(name: params[:categories])
        @contents = @contents.where(content_category_id: allowed_cats)
      end
      if params[:start_date].present?
        start_date = Chronic.parse(params[:start_date])
        @contents = @contents.where("pubdate >= :start_date", { start_date: start_date}) unless start_date.nil?
      end
      params[:page] ||= 1
      params[:per_page] ||= 30
      @contents = @contents.page(params[:page].to_i).per(params[:per_page].to_i)
      @page = params[:page]
      @pages = @contents.total_pages unless @contents.empty?
    end

  end

  def show
    @content = Content.find(params[:id])
    if params[:repository].present? and @content.present?
      repo = @content.repositories.find_by_dsp_endpoint params[:repository]
      @content = nil if repo.nil?
    end
  end

  # for now, this doesn't need to handle images
  def create_and_publish
    # REVERSE PUBLISHING
    # PHASE 1
    # First we establish whether or not something is supposed to be reverse published.
    # If YES, we construct an email to the reverse_publishing_email of the publication
    # and send it from the user email provided.
    # If NO, we follow our normal create-and-publish mechanism.

    # hack to identify beta_talk category contents
    # and automatically set the publication based on category
    category = params[:content][:category]
    source = params[:content].delete :source
    if category == "beta_talk"
      pub = Publication.find_or_create_by_name "Beta Talk"
    else
      pub = Publication.find_by_name(source)
    end

    # create content here so we can pass it to mailer OR create it
    # in PHASE 2 we will be doing both
    cat_name = params[:content].delete :category
    cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?
    if params[:content][:content].present?
      params[:content][:raw_content] = params[:content].delete :content
    end
    @content = Content.new(params[:content])
    @content.source = pub
    @content.content_category = cat unless cat.nil?
    @content.pubdate = @content.timestamp = Time.zone.now

    # this is where we branch for reverse publishing
    if pub.reverse_publish_email.present?
      ReversePublisher.send_content_to_reverse_publishing_email(@content, pub).deliver
      render text: "Post sent to listserve, it should appear momentarily", status: 200
    else
      repo = Repository.find_by_dsp_endpoint(params[:repository])

      if @content.save
        if @content.publish(Content::POST_TO_ONTOTEXT, repo)
          render text: "#{@content.id}"
        else
          render text: "Content was created, but not published", status: 500
        end
      else
        render text: "Content could not be created", status: 500
      end
    end
  end

  # returns hash of IDs representing a full thread of conversation
  def get_tree
    if Content.exists? params[:id]
      @content = Content.find params[:id] 
      @repo = Repository.find_by_dsp_endpoint(params[:repository])
      thread = @content.get_full_ordered_thread
      # requested to remove this functionality because our published flag
      # is not always accurate right now. NG's opinion is that we should work
      # on making the published flag accurate rather than removing this filter
      # but to each their own I suppose.
      #thread.select! { |pair| @repo.contents.include? Content.find(pair[0]) }
      render json: thread.to_json
    else
      render json: {}
    end
  end

  def banner
    @content = Content.find(params[:id])
    @repo = Repository.find_by_dsp_endpoint(params[:repository])
    begin
      promoted_content_id = @content.get_related_promotion(@repo)
      new_content = Content.find promoted_content_id
    rescue
      new_content = nil
    end

    if new_content.nil?
      render json: {}
    else
      render json: { banner: new_content.promotions.where(active: true).first.banner.url, content_id: new_content.id }
    end
  end

  def search
    query = Riddle::Query.escape(params[:query])

    params[:page] ||= 1
    params[:per_page] ||= 30

    opts = { select: '*, weight()', excerpts: { limit: 350, around: 5, html_strip_mode: "strip" } }
    opts[:order] = 'timestamp DESC' if params[:order] == 'pubdate'
    opts[:per_page] = params[:per_page]
    opts[:page] = params[:page]

    opts[:with] = {}

    if params[:repository].present?
      repo = Repository.find_by_dsp_endpoint(params[:repository])
      return if repo.nil?
      opts[:with].merge!({repo_ids: repo.id})
    end
    if params[:publications].present?
      allowed_pubs = Publication.where(name: params[:publications]).collect{|p| p.id}
      opts[:with].merge!({:pub_id => allowed_pubs})
    end
    if params[:categories].present?
      allowed_cats = ContentCategory.find_with_children(name: params[:categories]).collect{|c| c.id}
      opts[:with].merge!({:cat_ids => allowed_cats})
    end

    @contents = Content.search query, opts
    @contents.context[:panes] << ThinkingSphinx::Panes::WeightPane
    @contents.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane
    @page = @contents.current_page 
    @pages = @contents.total_pages
  end


  # as of now, the only updating we're doing is marking things reviewed
  # so for security's sake, that's all this method can do.
  def update
    @content = Content.find(params[:id])
    if params[:content][:category_reviewed].present?
      @content.update_attribute :category_reviewed, params[:content][:category_reviewed]
      # requested to create a (essentially) blank category_correction object when marking reviewed
      if params[:content][:category_reviewed] # if true
        CategoryCorrection.create(content: @content, new_category: @content.category, old_category: @content.category)
      end
    end
  end

  private

  # detects if the route is through events
  # and sets params[:events] = true if so
  # in order to allow action to respond accordingly
  def set_events_param
    # if it is passed in already, don't set it
    unless params[:events].present?
      if request.url.match /events/
        params[:events] = true
      else
        params[:events] = false
      end
    end
  end
end
