class Api::EventInstancesController < Api::ApiController
  def featured_events
    # pull all events that are featured and upcoming ordered by start_date (of the event instances)
    @event_instances = EventInstance.where("start_date >= ?", DateTime.now).joins(:event).where("events.featured = true")

    # filter by repository
    if params[:repository].present?
      @event_instances = @event_instances.joins(event: :repositories).where(repositories: {dsp_endpoint: params[:repository]}) 
    end
    @event_instances = @event_instances.order("start_date ASC").limit(5)
    render "index"
  end

  def index
    @event_instances = EventInstance.joins(:event)
    if params[:max_results].present? 
      @event_instances = @event_instances.limit(params[:max_results])
    else
      @event_instances = @event_instances.limit(1000)
    end
    @event_instances = @event_instances

    if params[:sort_order].present? and ['DESC', 'ASC'].include? params[:sort_order] 
      sort_order = params[:sort_order]
    end

    # TODO: this repository filtering stuff is replicated here *and* in the corresponding
    # places in the api/contents controller. Would be neat to abstract it 
    # which would save us a few lines of code and maybe make things a bit clearer.
    if params[:repository].present?
      @event_instances = @event_instances.joins(event: :repositories).where(repositories: { dsp_endpoint: params[:repository] }) 
    end

    sort_order ||= "ASC"
    @event_instances = @event_instances.order("start_date #{sort_order}")

    if params[:start_date].present?
      start_date = Chronic.parse(params[:start_date]).beginning_of_day
      @event_instances = @event_instances.where('start_date >= ?', start_date)
    end
    if params[:end_date].present?
      end_date = Chronic.parse(params[:end_date]).end_of_day
      if end_date == start_date
        end_date = start_date.end_of_day
      end
      @event_instances = @event_instances.where('start_date <= ?', end_date)
    end

    # don't return featured events unless they're requested
    unless params[:request_featured].present?
      @event_instances = @event_instances.where(events: { featured: false })
    end
  end

  def show
    @event_instance = EventInstance.find(params[:id])
    if params[:repository].present? and @event_instance.present?
      repo = @event_instance.event.repositories.find_by_dsp_endpoint params[:repository]
      @event_instance = nil if repo.nil?
    end
  end

end
