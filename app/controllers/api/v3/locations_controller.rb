# frozen_string_literal: true

module Api
  module V3
    class LocationsController < ApiController
      def index
        expires_in 1.hour, public: true

        if params[:query].present?
          @locations = Location.search(params[:query], limit: 10)
        elsif params[:near].present?
          if params[:radius].present?

            radius = params[:radius].to_i
            location = Location.find_by_slug_or_id(params[:near])

            @locations = Location.with_slug.consumer_active.non_region.within_radius_of(location, radius)

          else
            render(json: { errors: ['radius must be specified'] }, status: 422) && return
          end
        else # not a radius query

          @locations = Location.with_slug.consumer_active.not_upper_valley.order('city ASC')
        end

        render json: @locations, each_serializer: LocationSerializer
      end

      def show
        expires_in 1.hour, public: true

        @location = Location.find_by_slug_or_id(params[:id])
        if @location.present?
          render json: @location, serializer: LocationSerializer
        else
          render json: {}, status: :not_found
        end
      end
    end
  end
end
