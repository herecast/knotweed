module Api
  module V3
    class EventInstances::ActiveDatesController < ApiController

      def index
        expires_in 1.minutes, public: true
        render json: { active_dates: active_dates }.to_json, root: 'active_dates'
      end

      private

      def active_dates
        expires_in 1.minutes, public: true
        @active_dates ||= begin
          opts = { load: false, limit: 0 }
          opts[:where] = {}
          apply_query_date_range opts
          apply_query_location_filters opts

          requested_start = (params[:start_date].present? ? DateTime.parse(params[:start_date]) : DateTime.now)
          timezone_offset = params[:start_date].present? ? requested_start.zone : Time.zone.now.strftime('%z')

          # Searchkick doesn't let this pass through directly
          # unless we use body_options
          opts[:body_options] = {
            aggs: {
              records_by_date: {
                date_histogram: {
                  field: :starts_at,
                  interval: :day,
                  time_zone: timezone_offset,
                  format: 'yyyy-MM-dd'
                }
              }
            }
          }

          query = params[:query].present? ? params[:query] : '*'

          results = EventInstance.search(query, opts).aggs['records_by_date']['buckets']

          mapped_results = results.select do |result|
            result['doc_count'] > 0
          end.map do |result|
            {
              date: result['key_as_string'],
              count: result['doc_count']
            }
          end.sort_by { |result| result[:date] }
          mapped_results
        end
      end

      def apply_query_date_range(opts)
        if params[:start_date].present?
          start_date = Time.parse(params[:start_date])
        end

        start_date ||= Time.current

        end_date = if params[:end_date].present?
                     Time.parse(params[:end_date])
                   else
                     (start_date + 1.year).end_of_month
                   end
        opts[:where][:starts_at] = start_date..end_date
      end

      def apply_query_location_filters(opts)
        if location.present?
          opts[:where][:location_id] = { in: location.send(radius_method) }
        end
      end

    end
  end
end