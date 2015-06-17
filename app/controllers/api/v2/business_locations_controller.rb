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
          # it's been requested we also add a single result for city/state  search...
          cs_query = "@(city,state) #{Riddle::Query.escape(params[:query])}"
          cs_opts = { per_page: 1, star: true }
          cs = BusinessLocation.search(cs_query, cs_opts).first
          response_data = @venues.map{|v| "#{v.name} #{v.city} #{v.state}".strip }
          response_data.prepend "#{cs.city} #{cs.state}".strip
          render json: {
            locations: response_data
          }
        else
          render json: @venues, root: 'venues'
        end
      end

    end
  end
end
