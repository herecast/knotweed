module Api
  module V1
    class ListservsController < ApiController
      def index
        if params[:location_ids].present?
          location_ids = params[:location_ids].select{ |l| l.present? }.map{ |l| l.to_i }
          @listservs = Listserv.joins(:locations)
            .where('listservs_locations.location_id in (?)', [1])
        else
          @listservs = Listserv.all
        end
        render json: @listservs
      end
    end
  end
end
