module Api
  module V3
    class LocationsController < ApiController

      def index
        expires_in 1.hours, public: true
        @locations = Location.consumer_active.not_upper_valley

        render json: @locations, arrayserializer: LocationSerializer
      end

    end
  end
end
