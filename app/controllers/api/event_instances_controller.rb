class Api::EventInstancesController < Api::ApiController

  def featured_events
    # pull all events that are featured and upcoming ordered by start_date (of the event instances)
    @event_instances = EventInstance.where("event_instances.start_date >= ?", DateTime.now)
      .includes(event: [{content: :images}, :venue]).where("events.featured = true").limit(5)

    # filter by repository
    if params[:repository].present?
      @event_instances = @event_instances.where("contents.published = 1")
    end
    @event_instances = @event_instances.order("event_instances.start_date ASC").limit(5)
    render "index"
  end

  def index
    # need to make the "start_date_only" (calendar query) as efficient as possible:
    if params[:start_date_only]
      @event_instances = EventInstance.select("event_instances.start_date").uniq
      if params[:repository].present?
        @event_instances = @event_instances.joins(event: [:content]).where("contents.published = 1")
      end
    else
      @event_instances = EventInstance.includes(event: [{content: :images}, :venue])
      @event_instances = @event_instances.where("contents.published = 1") if params[:repository].present?
      # don't return featured events unless they're requested
      unless params[:request_featured].present?
        @event_instances = @event_instances.where(events: { featured: false })
      end
    end

    if params[:max_results].present? 
      @event_instances = @event_instances.limit(params[:max_results])
    else
      @event_instances = @event_instances.limit(10)
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

  end

  def show
    @event_instance = EventInstance.find(params[:id])
    if params[:repository].present? and @event_instance.present?
      repo = Repository.find_by_dsp_endpoint params[:repository]
      @event_instance = nil unless @event_instance.event.content.repositories.include? repo
    end
  end

end
