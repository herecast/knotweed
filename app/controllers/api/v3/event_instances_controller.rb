module Api
  module V3
    class EventInstancesController < ApiController
      
      def index
        expires_in 1.minutes, public: true
        opts = {}
        opts[:where] = {}
        opts[:order] = { start_date: :asc }
        opts[:per_page] = params[:per_page] || 25
        opts[:page] = params[:page] || 1

        if params[:date_start].present?
          start_date = Chronic.parse(params[:date_start]).beginning_of_day
        else
          start_date = Date.current.beginning_of_day
        end
        end_date = Chronic.parse(params[:date_end]).end_of_day if params[:date_end].present?

        opts[:where][:published] = 1 if @repository.present?

        if end_date.present?
          opts[:where][:start_date] = start_date..end_date
        else
          # NOTE: we can't do a `greater than` search with a Sphinx attribute filter
          # without some funny business that involves changing the index,
          # so instead we're just setting this to 1 year in advance.
          opts[:where][:start_date] = start_date..1.year.from_now
        end

        if params[:category].present?
          cat = params[:category].to_s.downcase.gsub(' ','_')
          if Event::EVENT_CATEGORIES.include?(cat.to_sym)
            # NOTE: this conditional also handles the scenario where we are passed 'everything'
            # because 'everything' just means don't filter by category, and since 'everything'
            # is not inside that constant, we're good.
            opts[:where][:event_category] = cat
          end
        end

        # if the location is a city or (city, state) pair that matches one of our local towns,
        # check if there are any villages (aka children) and include them in the search using the
        # venue attribute of the ES index
        # Otherwise, just search for the location
        query_location = Location.find_by_city_state(params[:location])
        if query_location.present?
          loc_array = ["#{query_location.city}"] + query_location.children.map{|l| "#{l.city}"}
          query = "#{params[:query]}"
          opts[:where][:venue] = loc_array
        else
          query = "#{params[:query]} #{params[:location]}"
        end

        query = query.present? ? query : '*'

        @event_instances = EventInstance.search query, opts

        render json: @event_instances, arrayserializer: EventInstanceSerializer,
          meta: { total: @event_instances.total_entries }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        @content = @event_instance.event.content
        if @current_api_user.present?
          url = edit_event_url(@event_instance.event) if @current_api_user.has_role? :admin
        end
        if @requesting_app.present?
          ical_url = @requesting_app.uri + event_instances_ics_path(params[:id]) 
        end
        @event_instance.event.content.increment_view_count! unless exclude_from_impressions?
        if @current_api_user.present? and @repository.present?
          BackgroundJob.perform_later_if_redis_available('DspService', 'record_user_visit',
                                                         @content, @current_api_user, @repository)
        end

        if request.headers['HTTP_ACCEPT'] == 'text/calendar'
          render text: @event_instance.to_ics
        else
          render json: @event_instance, root: 'event_instance', serializer: DetailedEventInstanceSerializer,
            context: { current_ability: current_ability, admin_content_url: url, ical_url: ical_url }
        end
      end
    end
  end
end
