module Api
  module V2
    class BusinessLocationsController < ApiController

      def index
        query = Riddle::Query.escape(params[:query]) if params[:query].present?
        if query.present?
          opts = {}
          opts = { select: '*, weight() as w', order: 'w DESC, name DESC' }
          opts[:per_page] = params[:max_results] || 1000
          opts[:star] = true
          @venues = BusinessLocation.search query, opts
        else
          @venues = BusinessLocation.all
        end

        if params[:autocomplete]
          render json: {
            locations: @venues.map{|v| "#{v.name} #{v.city} #{v.state}".strip }
          }
        else
          render json: @venues, root: 'venues'
        end
      end

    end
  end
end
