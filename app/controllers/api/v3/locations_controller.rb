module Api
  module V3
    class LocationsController < ApiController

      def index
        expires_in 1.hours, public: true
        @locations = Location.consumer_active.not_upper_valley

        render json: @locations, arrayserializer: LocationSerializer
      end

      def closest
        expires_in 1.hours, public: true
        location = Location.find params[:id]
        count = params[:count] || 8
        @locations = location.closest(count)
        render json: @locations, arrayserializer: LocationSerializer
      end

    end
  end
end
