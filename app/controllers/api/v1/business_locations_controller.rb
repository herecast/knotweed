module Api
  module V1
    class BusinessLocationsController < ApiController

      # shamelessly copied from models/publication.rb JGS 20141202

      # returns list of business locations filtered by consumer app (if provided)
      def index
        @businessLocations = BusinessLocation.select('id, name, address').order('name')
        render json: @businessLocations
      end

      def show
        if params[:id].present?
          @businessLocation = BusinessLocation.find(params[:id])
        elsif params[:name].present?
          @businessLocation = BusinessLocation.find_by_name(params[:name])
        end
        if @businessLocation.present?
          render :json => @businessLocation
        else
          render text: "No business location found.", status: 500
        end
      end

    end
  end
end
