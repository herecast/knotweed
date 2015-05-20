module Api
  module V2
    class BusinessLocationsController < ApiController

      def index
        query = Riddle::Query.escape(params[:query]) if params[:query].present?
        if query.present?
          opts = {}
          opts = { select: '*, weight()' }
          opts[:per_page] = params[:max_results] || 1000
          @venues = BusinessLocation.search query, opts
        else
          @venues = BusinessLocation.all
        end

        render json: @venues, root: 'venues'
      end

    end
  end
end
