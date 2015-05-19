module Api
  module V1
    class LocationsController < ApiController
      def index
        @locations = Location.where(consumer_active: true)
        render json: @locations
      end

      def show
        @location = Location.find(params[:id])
        render json: @location
      end
    end

  end
end
