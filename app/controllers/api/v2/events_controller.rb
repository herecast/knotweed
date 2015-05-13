module Api
  module V2
    class EventsController < ApiController

      def show
        @event = Event.find(params[:id])
        render json: @event, include_instances: true
      end

    end
  end
end
