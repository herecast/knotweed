module Api
  module V2
    class BusinessLocationsController < ApiController

      def index
        @venues = BusinessLocation.all
        render json: @venues, root: 'venues'
      end

    end
  end
end
