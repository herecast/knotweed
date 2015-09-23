module Api
  module V3
    class LocationsController < ApiController

      def index
        if params[:query].present?
          opts = { select: '*, weight()' }
          opts[:page] = params[:page] || 1
          opts[:per_page] = params[:per_page] || 12
          opts[:star] = true
          query = Riddle::Query.escape(params[:query]) 
          @locations = Location.search query, opts
        else
          @locations = Location.consumer_active.not_upper_valley
        end

        render json: @locations, arrayserializer: LocationSerializer
      end

    end
  end
end
