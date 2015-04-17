class Api::EventInstancesController < Api::ApiController

  def index
    # need to make the "start_date_only" (calendar query) as efficient as possible:
    if params[:start_date_only]
      @event_instances = EventInstance.select("event_instances.start_date").uniq
      if params[:repository].present?
        @event_instances = @event_instances.joins(event: [:content]).where("contents.published = 1")
      end
    else
      # TODO make image include conditional on view
      @event_instances = EventInstance.includes(event: [{content: :images}, :venue])
      #@event_instances = EventInstance.includes(event: [:venue])
      @event_instances = @event_instances.joins(event: [:content]).where("contents.published = 1") if params[:repository].present?
      # don't return featured events unless they're requested
      if params[:featured].present?
        @event_instances = @event_instances.where('events.featured = true')
      elsif !params[:include_featured].present?
        @event_instances = @event_instances.where(events: { featured: false })
      end
    end

    # removing the "featured_events" api call because it doesn't make sense
    if params[:featured].present?
      @event_instances = @event_instances.where('events.featured = true')
    end

    # location filtering
    if params[:locations].present?
      # avoid SQL injection
      locations = params[:locations].map{ |l| l.to_i }
      @event_instances = @event_instances.joins('inner join contents_locations on contents.id ' +
        '= contents_locations.content_id')
        .where('contents_locations.location_id in (?)', locations)
    end

    if params[:max_results].present? 
      @event_instances = @event_instances.limit(params[:max_results])
    else
      @event_instances = @event_instances.limit(1000)
    end

    if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
      sort_order = params[:sort_order]
    end

    sort_order ||= "ASC"
    @event_instances = @event_instances.order("event_instances.start_date #{sort_order}")

    if params[:start_date].present?
      start_date = Chronic.parse(params[:start_date]).beginning_of_day
      @event_instances = @event_instances.where('event_instances.start_date >= ?', start_date)
    end
    if params[:end_date].present?
      end_date = Chronic.parse(params[:end_date]).end_of_day
      if end_date == start_date
        end_date = start_date.end_of_day
      end
      @event_instances = @event_instances.where('event_instances.start_date <= ?', end_date)
    end

    # for the dashboard, if there's an author email, just return their content records.
    @event_instances = @event_instances.joins(event:[:content]).where('contents.authoremail = ?', params[:authoremail]) if params[:authoremail].present?

  end

  def show
    @event_instance = EventInstance.find(params[:id])
    if params[:repository].present? and @event_instance.present?
      @event_instance = nil unless @event_instance.event.content.published
    end
  end

  def search
    query = Riddle::Query.escape(params[:query])

    params[:page] ||= 1
    params[:per_page] ||= 30
    opts = {}
    opts = { select: '*, weight()' }
    opts[:order] = 'start_date ASC'
    opts[:per_page] = params[:per_page]
    opts[:page] = params[:page]

    opts[:with] = {:start_date => Time.now..60.days.from_now}

    @event_instances = EventInstance.search query, opts
  end

end
