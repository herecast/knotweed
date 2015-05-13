module Api
  module V2
    class EventInstancesController < ApiController

      def index
        @event_instances = EventInstance.limit(100).order('start_date ASC')
          .includes(event: [{content: :images}, :venue])

        if params[:date_start].present?
          start_date = Chronic.parse(params[:date_start]).beginning_of_day
          @event_instances = @event_instances.where('event_instances.start_date >= ?', start_date)
        end
        if params[:date_end].present?
          end_date = Chronic.parse(params[:date_end]).end_of_day
          if end_date == start_date
            end_date = start_date.end_of_day
          end
          @event_instances = @event_instances.where('event_instances.start_date <= ?', end_date)
        end

        render json: @event_instances, root: 'events'
      end

      def show
        @event_instance = EventInstance.find(params[:id])
        render json: @event_instance, root: 'event', serializer: DetailedEventInstanceSerializer
      end

    end
  end
end
