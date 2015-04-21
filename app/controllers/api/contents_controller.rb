class Api::ContentsController < Api::ApiController

  def index
    params[:page] ||= 1
    params[:per_page] ||= 30
    if params[:query].present?
      query = Riddle::Query.escape(params[:query])

      opts = { select: '*, weight()', excerpts: { limit: 350, around: 5, html_strip_mode: "strip" } }
      opts[:order] = 'pubdate DESC' if params[:order] == 'pubdate'
      opts[:per_page] = params[:per_page]
      opts[:page] = params[:page]

      opts[:with] = {}
      opts[:conditions] = {}

      # have to duplicate a lot of the non-search logic here because Sphinx doesn't
      # allow us to use activerecord scopes
      #
      opts[:conditions].merge!({published: 1}) if params[:repository].present?

      if @requesting_app.present?
        allowed_pubs = @requesting_app.publications
        if params[:publications].present? # allows the My List / All Lists filter to work
          filter_pubs = Publication.where(name: params[:publications])
          allowed_pubs.select! { |p| filter_pubs.include? p }
        end
        opts[:with].merge!({pub_id: allowed_pubs.collect{|c| c.id} })
      end

      if params[:categories].present?
        allowed_cats = ContentCategory.find_with_children(name: params[:categories]).collect{|c| c.id}
        opts[:with].merge!({:cat_ids => allowed_cats})
      end

      opts[:conditions].merge!({channelized_content_id: nil}) # note, that's how sphinx stores NULL

      if params[:locations].present?
        locations = params[:locations].map{ |l| l.to_i } 
        opts[:with].merge!({loc_ids: locations})
      end

      @contents = Content.search query, opts
      @contents.context[:panes] << ThinkingSphinx::Panes::WeightPane
      @contents.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane
      @page = @contents.current_page 
      @pages = @contents.total_pages
    else
      if params[:max_results].present? 
        @contents = Content.limit(params[:max_results])
      else
        @contents = Content
      end
      # exclude channelized content from all content api queries
      @contents = @contents.where("channelized_content_id IS NULL")

      @contents = @contents.includes(:publication).includes(:content_category).includes(:images)

      if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
        sort_order = params[:sort_order]
      end

      sort_order ||= "DESC"
      @contents = @contents.order("pubdate #{sort_order}")
      # filter contents by publication based on what publications are allowed
      # for the incoming consumer app
      if @requesting_app.present?
        allowed_pubs = @requesting_app.publications
        # if viewing just the home list
        @contents = @contents.where(publication_id: allowed_pubs)
      end
      if params[:start_date].present?
        start_date = Chronic.parse(params[:start_date])
        @contents = @contents.where("pubdate >= :start_date", { start_date: start_date}) unless start_date.nil?
      end
      if params[:categories].present?
        allowed_cats = ContentCategory.find_with_children(name: params[:categories])
        @contents = @contents.where(content_category_id: allowed_cats)
      end

      # filter by location
      if params[:locations].present?
        locations = params[:locations].map{ |l| l.to_i } # avoid SQL injection
        @contents = @contents.joins('inner join contents_locations on contents.id = contents_locations.content_id')
          .where('contents_locations.location_id in (?)', locations)
      end

      # workaround to avoid the extremely costly contents_repositories inner join
      # using the new "published" boolean on the content model
      # to avoid breaking specs and more accurately replicate the old behavior,
      # we're only introducing this condition when a repository parameter is provided.
      @contents = @contents.published if params[:repository].present?

      # for the dashboard, if there's an author email, just return their content records.
      @contents = @contents.where(authoremail: params[:authoremail]) if params[:authoremail].present?
    end

    @contents = @contents.page(params[:page].to_i).per(params[:per_page].to_i)
    @page = params[:page]
    @pages = @contents.total_pages unless @contents.empty?
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
    pubname = params[:content].delete :publication
    if category == "beta_talk"
      pub = Publication.find_or_create_by_name "Beta Talk"
    else
      pub = Publication.find_by_name(pubname)
    end

    # create content here so we can pass it to mailer OR create it
    # in PHASE 2 we will be doing both
    cat_name = params[:content].delete :category
    cat = ContentCategory.find_or_create_by_name(cat_name) unless cat_name.nil?
    if params[:content][:content].present?
      params[:content][:raw_content] = params[:content].delete :content
    end
    @content = Content.new(params[:content])
    @content.publication = pub
    @content.content_category = cat unless cat.nil?
    @content.pubdate = @content.timestamp = Time.zone.now
		@content.images=[@image] unless @image.nil?

    # this is where we branch for reverse publishing
    if pub.present? and pub.reverse_publish_email.present?
      ReversePublisher.send_content_to_reverse_publishing_email(@content, pub).deliver
      # need to send separate email to user rather than CC because their spam filter would catch
      # us spoofing emails "from" them
      ReversePublisher.send_copy_to_sender_from_dailyuv(@content, pub).deliver
      render text: "Post sent to listserve, it should appear momentarily", status: 200
    else
      repo = Repository.find_by_dsp_endpoint(params[:repository])

      if @content.save
        if @content.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
          render text: "#{@content.id}"
        else
          render text: "Content #{@content.id} was created, but not published", status: 500
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
      promo = new_content.promotions.where(active: true).first
      render json: { banner: promo.banner.url, 
                     target_url: promo.target_url, content_id: new_content.id }
    end
  end

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

  def moderate
    @message = 'success'

    begin
      content = Content.find(params[:id])
      subject = 'dailyUV Flagged as ' + params[:classification] + ': ' +  content.title

      ModerationMailer.send_moderation_flag(content, params, subject).deliver

    rescue Exception => e
      @message = e.message
    end
  end


end
