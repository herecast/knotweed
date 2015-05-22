module Api
  module V2
    class EventInstancesController < ApiController

      def index
        #if params[:query].present? or params[:location].present?
        query = Riddle::Query.escape("#{params[:query]} #{params[:location]}")

        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'start_date ASC'
        opts[:per_page] = params[:max_results] || 1000
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:sql] = { include: {event: [{content: :images}, :venue]}}

        start_date = Chronic.parse(params[:date_start]) if params[:date_start].present?
        end_date = Chronic.parse(params[:date_end]) if params[:date_end].present?

        if start_date.present?
          if end_date.present?
            opts[:with].merge!({ start_date: start_date..end_date })
          else
            opts[:with].merge!({ start_date: start_date..60.days.from_now })
          end
        elsif end_date.present?
          opts[:with].merge!({ start_date: Time.now..end_date })
        end

        if params[:category].present?
          cat = params[:category].to_s.downcase.gsub(' ', '_')
          if Event::EVENT_CATEGORIES.include?(cat.to_sym)
            # NOTE: this conditional also handles the scenario where we are passed 'everything'
            # because 'everything' just means don't filter by category, and since 'everything'
            # is not inside that constant, we're good.
            opts[:conditions].merge!({ event_category: cat })
          end
        end

        @event_instances = EventInstance.search query, opts

        render json: @event_instances, meta: { total: EventInstance.count }
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        render json: @event_instance, serializer: DetailedEventInstanceSerializer
      end

    end
  end
end
