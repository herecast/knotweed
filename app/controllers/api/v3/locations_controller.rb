module Api
  module V3
    class LocationsController < ApiController

      def index
        expires_in 1.minute, public: true
        @locations = Location.consumer_active.not_upper_valley.order('city ASC')

        render json: @locations, arrayserializer: LocationSerializer
      end

      def closest
        expires_in 1.hours, public: true
        location = Location.find params[:id]
        count = params[:count] || 8
        @locations = location.closest(count)
        render json: @locations, arrayserializer: LocationSerializer
      end

      def show
        @location = Location.find_by_slug_or_id(params[:id])
        if @location.present?
          render json: @location, serializer: LocationSerializer
        else
          render json: {}, status: :not_found
        end
      end

      # endpoint for establishing user location
      # returns serialized location
      def locate
        if params[:coords]
          coords = params[:coords].split(',')
          @location= Location.non_region.consumer_active.nearest_to_coords(
            latitude: coords[0],
            longitude: coords[1]
          ).first
        elsif current_user && current_user.location
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
