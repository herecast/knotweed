class Api::ContentsController < Api::ApiController
  before_filter :set_events_param

  def index
    if params[:max_results].present? 
      @contents = Content.events.limit(params[:max_results])
    end
    if params[:events]
      if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
        sort_order = params[:sort_order]
      else
        sort_order = 'ASC'
      end

      if @contents.nil?
        @contents = Content.events.order("start_date #{sort_order}")
      else
        @contents = @contents.order("start_date #{sort_order}")
      end
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

      if params[:request_featured].present?
        @featured_contents = @contents.clone
        @contents = @contents.where('featured = false')
        @featured_contents = @featured_contents.limit(5)
        @featured_contents = @featured_contents.where('featured = true')
      end
    end

    if params[:repository].present? and @contents.present?
      repo = Repository.find_by_dsp_endpoint(params[:repository])
      @contents = @contents.select { |c| c.repositories.include? repo }
    end

    @contents = (@contents + @featured_contents).sort{|a, b| a.start_date <=> b.start_date } unless @featured_contents.nil?

    render json: @contents || nil
  end

  def show
    @content = Content.find(params[:id])
    render json: Content.find(params[:id])
  end

  # for now, this doesn't need to handle images
  def create_and_publish
    # find source_id from source name
    source = params[:content].delete :source
    pub = Publication.find_by_name(source)
    repo = Repository.find_by_dsp_endpoint(params[:repository])

    @content = Content.new(params[:content])
    @content.source = pub
    @content.pubdate = @content.timestamp = Time.zone.now
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
      render json: { banner: new_content.promotions.first.banner.url, content_id: new_content.id }
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
