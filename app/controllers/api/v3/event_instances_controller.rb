module Api
  module V3
    class EventInstancesController < ApiController

      def index
        expires_in 1.minutes, public: true
        @opts = {}
        @opts[:order] = { start_date: :asc }
        @opts[:per_page] = params[:per_page]
        @opts[:page] = params[:page] || 1
        @opts[:where] = {}
        @opts[:where][:published] = 1 if @repository.present?
        set_date_range

        if params[:category].present? && params[:category] != 'Everything'
          @event_instances = GetEventsByCategories.call(params[:category], @opts)
        else
          query = params[:query].present? ? params[:query] : "*"
          @event_instances = EventInstance.search(query, @opts)
        end

        render json: @event_instances, each_serializer: EventInstanceSerializer,
          meta: { total: @event_instances.try(:count) || 0 }
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

      def create_impression
        @event_instance = EventInstance.find(params[:id])
        if @event_instance.present?
          @event_instance.event.content.increment_view_count! unless analytics_blocked?
          render json: {}, status: :accepted
        else
          render json: {}, status: :not_found
        end
      end

      private

        def set_date_range
          start_date = Chronic.parse(params[:date_start]).try(:beginning_of_day) || Date.current.beginning_of_day
          if params[:days_ahead].present?
            end_date = start_date + params[:days_ahead].to_i.days
          elsif params[:category].present?
            end_date = start_date + 7.days
          else
            end_date = start_date + 1.day
          end
          @opts[:where][:start_date] = start_date..end_date
        end

    end
  end
end
