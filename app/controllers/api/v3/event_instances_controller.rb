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
        @opts[:where][:removed] = { not: true }
        set_date_range

        if params[:location_id].present?
          @opts[:where][:or] ||= []
          location = Location.find_by_slug_or_id(params[:location_id])

          if params[:radius].present? && params[:radius].to_i > 0
            locations_within_radius = Location.within_radius_of(location, params[:radius].to_i).map(&:id)

            @opts[:where][:or] << [
              {my_town_only: false, all_loc_ids: locations_within_radius},
              {my_town_only: true, all_loc_ids: [location.id]}
            ]
          else
            @opts[:where][:or] << [
              {base_location_ids: [location.id]},
              {about_location_ids: [location.id]}
            ]
          end
        end

        if params[:category].present? && params[:category] != 'Everything'
          @event_instances = GetEventsByCategories.call(params[:category], @opts)
        else
          query = params[:query].present? ? params[:query] : "*"
          @event_instances = EventInstance.search(query, @opts)
        end

        render json: @event_instances, each_serializer: EventInstanceSerializer,
          meta: { total: @event_instances.try(:total_entries) || @event_instances.count }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        if @current_api_user.present?
          url = edit_event_url(@event_instance.event) if @current_api_user.has_role? :admin
        end
        if @requesting_app.present?
          ical_url = @requesting_app.uri + event_instances_ics_path(params[:id])
        end

        if @event_instance.event.content.removed?
          update_event_instance_as_removed
        end

        if request.headers['HTTP_ACCEPT'] == 'text/calendar'
          render text: @event_instance.to_ics
        else
          render json: @event_instance, root: 'event_instance', serializer: DetailedEventInstanceSerializer,
            context: { current_ability: current_ability, admin_content_url: url, ical_url: ical_url }
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

        def update_event_instance_as_removed
          dupe = CreateAlternateContent.call(@event_instance.event.content)
          @event_instance.event.define_singleton_method(:content) { dupe }
          [:venue, :contact_phone, :contact_email, :event_url].each do |sym|
            @event_instance.event.define_singleton_method(sym) { nil }
          end
        end

    end
  end
end
