module Api
  module V3
    class EventInstancesController < ApiController

      def index
#        expires_in 1.minutes, public: true
        opts = {load: false}
        opts[:order] = [
          { starts_at: :asc },
          { venue_name: :asc },
          { title: :asc }
        ]
        opts[:where] = {}
        opts[:where][:published] = 1 if @repository.present?
        opts[:where][:removed] = { not: true }
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 20

        apply_date_query opts
        apply_query_location_filters opts

        query = params[:query].present? ? params[:query] : "*"
        @event_instances = EventInstance.search(query, opts)

        total_pages = ((@event_instances.total_count || 100) / opts[:per_page].to_f).ceil
        render json: @event_instances, each_serializer: HashieMashes::DetailedEventInstanceSerializer,
          meta: {
            count: @event_instances.count,
            total: @event_instances.try(:total_count) || @event_instances.count,
            total_pages: total_pages
          }
      end

      def sitemap_ids
        data = EventInstance.joins(event: :content).merge(
          Content
          .published
          .not_deleted
          .not_listserv
          .not_removed
          .is_dailyuv
          .where('pubdate <= ?', Time.zone.now)
        ).order('start_date DESC')\
          .limit(50_000)\
          .select('event_instances.id as id, contents.id as content_id')

        render json: {
          instances: data.map do |instance|
            {
              id: instance.id,
              content_id: instance.content_id
            }
          end
        }
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
          render json: @event_instance, root: 'event_instance', serializer: EventInstanceSerializer,
            context: { current_ability: current_ability, admin_content_url: url, ical_url: ical_url }
        end
      end

      def active_dates
        expires_in 1.minutes, public: true
        render json: {active_dates: _active_dates}.to_json, root: 'active_dates'
      end

      private

        def _active_dates
          @_active_dates ||= begin
            opts = {load: false, limit: 0}
            opts[:where] = {}
            opts[:where][:published] = 1 if @repository.present?
            apply_query_date_range opts
            apply_query_location_filters opts

            requested_start = (params[:start_date].present? ? DateTime.parse(params[:start_date]) : DateTime.now)
            timezone_offset = params[:start_date].present? ? requested_start.zone : Time.zone.now.strftime('%z')

            # Searchkick doesn't let this pass through directly
            # unless we use body_options
            opts[:body_options] ={
              aggs: {
                records_by_date: {
                  date_histogram: {
                    field: :starts_at,
                    interval: :day,
                    time_zone: timezone_offset,
                    format: "yyyy-MM-dd"
                  }
                }
              }
            }

            query = params[:query].present? ? params[:query] : "*"

            results = EventInstance.search(query, opts).aggs['records_by_date']['buckets']

            mapped_results = results.select do |result|
              result['doc_count'] > 0
            end.map do |result|
              EventInstanceActiveDate.new(
                date: result['key_as_string'],
                count: result['doc_count']
              )
            end.sort_by(&:date)
            mapped_results
          end
        end

        def apply_query_date_range(opts)
          if params[:start_date].present?
            start_date = Time.parse(params[:start_date])
          end

          start_date ||= Time.current

          if params[:end_date].present?
            end_date = Time.parse(params[:end_date])
          else
            end_date = (start_date + 1.year).end_of_month
          end
          opts[:where][:starts_at] = start_date..end_date
        end

        def apply_date_query(opts)
          start_date = (params[:start_date].present? ? DateTime.parse(params[:start_date]) : DateTime.now)
          end_date = (params[:end_date].present? ? DateTime.parse(params[:end_date]) : nil)

          if end_date.present?
            opts[:where][:starts_at] = start_date.beginning_of_day..end_date.end_of_day
          else
            opts[:where][:starts_at] = {gte: start_date}
          end
        end

        def apply_query_location_filters(opts)
          if params[:location_id].present?
            opts[:where][:or] ||= []
            location = Location.find_by_slug_or_id(params[:location_id])

            if params[:radius].present? && params[:radius].to_i > 0
              locations_within_radius = Location.within_radius_of(location, params[:radius].to_i).map(&:slug).compact

              opts[:where][:base_location_ids] = { in: locations_within_radius }
            else
              opts[:where][:base_location_ids] = { in: [location.slug] }
            end
          end
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
