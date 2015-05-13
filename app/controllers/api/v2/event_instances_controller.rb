module Api
  module V2
    class EventInstancesController < ApiController

      def index
        @event_instances = EventInstance.limit(100).order('start_date ASC')

        if params[:starts_at].present?
          start_date = Chronic.parse(params[:starts_at]).beginning_of_day
          @event_instances = @event_instances.where('event_instances.start_date >= ?', start_date)
        end
        if params[:ends_at].present?
          end_date = Chronic.parse(params[:ends_at]).end_of_day
          if end_date == start_date
            end_date = start_date.end_of_day
          end
          @event_instances = @event_instances.where('event_instances.start_date <= ?', end_date)
        end

        render json: @event_instances, include_event: true
      end

    end
  end
end
