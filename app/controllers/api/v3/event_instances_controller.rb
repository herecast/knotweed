module Api
  module V3
    class EventInstancesController < ApiController
      
      before_filter :check_logged_in!, only: [:destroy]
      after_filter :track_index, only: :index

      def destroy
        @event_instance = EventInstance.find(params[:id])
        if @current_api_user.email != @event_instance.event.content.authoremail
          render json: { errors: ['You do not have permission to edit this event.'] }, 
            status: 401
        else
          if @event_instance.destroy
            head :no_content
          else
            render json: { errors: @event_instance.errors }
          end
        end
      end

      def index

        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'start_date ASC'
        opts[:per_page] = params[:per_page] || 25
        opts[:page] = params[:page] || 1
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:sql] = { include: {event: [{content: :images}, :venue]}}

        start_date = Chronic.parse(params[:date_start]).beginning_of_day if params[:date_start].present?
        end_date = Chronic.parse(params[:date_end]).end_of_day if params[:date_end].present?

        opts[:with][:published] = 1 if @repository.present?

        if start_date.present?
          if end_date.present?
            opts[:with][:start_date] = start_date..end_date
          else
            opts[:with][:start_date] = start_date..60.days.from_now
          end
        elsif end_date.present?
          opts[:with][:start_date] = Time.now..end_date 
        end

        if params[:category].present?
          cat = params[:category].to_s.downcase.gsub(' ','_')
          if Event::EVENT_CATEGORIES.include?(cat.to_sym)
            # NOTE: this conditional also handles the scenario where we are passed 'everything'
            # because 'everything' just means don't filter by category, and since 'everything'
            # is not inside that constant, we're good.
            opts[:conditions][:event_category] = cat
          end
        end

        # if the location is a city or (city, state) pair that matches one of our local towns,
        # check if there are any villages (aka children) and include them in the search using the name
        # field of the sphinx EventInstance index.
        # Otherwise, just search for the location
        query_location = Location.find_by_city_state(params[:location])
        if query_location.present?
          loc_array = ["(#{query_location.city})"] + query_location.children.map{|l| "(#{l.city})"}
          locations = loc_array.join('|')
          query = Riddle::Query.escape("#{params[:query]}")
          opts[:conditions][:name] = locations
        else
          query = Riddle::Query.escape("#{params[:query]} #{params[:location]}")
        end

        @event_instances = EventInstance.search query, opts

        render json: @event_instances, arrayserializer: EventInstanceSerializer,
          meta: { total: EventInstance.count }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        if @current_api_user.present?
          url = edit_event_url(@event_instance.event) if @current_api_user.has_role? :admin
        end
        can_edit = (@current_api_user.present? && (@event_instance.event.content.created_by == @current_api_user))
        @event_instance.event.content.increment_integer_attr!(:view_count)
        render json: @event_instance, root: 'event_instance', serializer: DetailedEventInstanceSerializer,
          can_edit: can_edit, admin_content_url: url
      end

      private

      def track_index
        props = {}
        props.merge! @tracker.navigation_properties('Event','event.index', url_for, params[:page])

        props.merge! @tracker.search_properties(params[:category], params[:start_date], params[:end_date], params[:location], params[:query], nil)

        @tracker.track(@current_api_user.try(:id), 'searchContent', @current_api_user, props)
      end

    end
  end
end
