module Api
  module V3
    class LocationsController < ApiController

      def index
        @locations = Location.consumer_active

        render json: @locations, arrayserializer: LocationSerializer
      end

    end
  end
end
