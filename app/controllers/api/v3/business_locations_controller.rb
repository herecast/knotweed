module Api
  module V3
    class BusinessLocationsController < ApiController

      def index
        expires_in 1.minutes, :public => true
        query = params[:query].blank? ? '*' : params[:query]
        opts = {}
        opts[:order] = { _score: :desc, name: :desc }
        opts[:per_page] = params[:max_results] || 1000
        opts[:where] = {}
        if @current_api_user.present?
          opts[:where][:or] = [
            [{created_by: @current_api_user.id}, {status: 'approved'}]
          ]
        else
          opts[:where][:status] = 'approved'
        end

        @venues = BusinessLocation.search query, opts

        if params[:autocomplete]
          # it's been requested we also add a single result for city/state  search...
          cs_query = params[:query]
          # The following two lines search extract the (city,state) pair from the search results,
          # then sets cs to the most frequently occurring (city,state) pair
          cities = BusinessLocation.search(cs_query).map{|c| c.city.strip + ', ' + c.state.strip}
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
            venue_locations: response_data
          }
        else
          render json: @venues, root: 'venues', arrayserializer: BusinessLocationSerializer
        end
      end

    end
  end
end
