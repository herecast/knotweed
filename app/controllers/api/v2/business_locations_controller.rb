module Api
  module V2
    class BusinessLocationsController < ApiController

      def index
        query = Riddle::Query.escape(params[:query]) if params[:query].present?
        if query.present?
          opts = {}
          opts = { select: '*, weight() as w', order: 'w DESC, name DESC' }
          if params[:autocomplete]
            per_page = [params[:max_results], 25].max if params[:max_results].present?
          else
            per_page = params[:max_results]
          end
          opts[:per_page] = per_page || 1000
          opts[:star] = true
          @venues = BusinessLocation.search query, opts
        else
          @venues = BusinessLocation.all
        end

        if params[:autocomplete]
          # it's been requested we also add a single result for city/state  search...
          cs_query = "@(city,state) #{Riddle::Query.escape(params[:query])}"
          cs_opts = { star: true }
          # The following two lines search extract the (city,state) pair from the search results,
          # then sets cs to the most frequently occurring (city,state) pair
          cities = BusinessLocation.search(cs_query, cs_opts).map{|c| c.city.strip + ', ' + c.state.strip}
          cs = cities.group_by{|n| n }.values.max_by(&:size)

          # reorganize the responses from the search so the locations that begin with the query
          # string appear first, then follow with whatever is left and params[:max_results] results
          response_data = @venues.map{|v| "#{v.name} #{v.city}, #{v.state}".strip }
          leftmost_matches = response_data.select{|v| v=~ /^#{query}/}.sort
          response_data = leftmost_matches + (response_data - leftmost_matches)
          response_data = response_data.slice(0..params[:max_results]-1) if params[:max_results].present?

          # stick in the matched city at the top of the returned data
          response_data.prepend "#{cs.first}" if cs.present?
          render json: {
            locations: response_data
          }
        else
          render json: @venues, arrayserializer: BusinessLocationSerializer, root: 'venues'
        end
      end

    end
  end
end
