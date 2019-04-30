module Api
  module V3
    class Locations::FindsController < ApiController

      def show
        if params[:coords]
          coords = params[:coords].split(',')
          @location = Location.non_region.consumer_active.nearest_to_coords(
            latitude: coords[0],
            longitude: coords[1]
          ).first
        elsif current_user&.location
          @location = current_user.location
        else
          @location = Location.non_region.consumer_active.nearest_to_ip(
            request.remote_ip
          ).first
        end

        render json: @location, serializer: LocationSerializer
      end
    end
  end
end