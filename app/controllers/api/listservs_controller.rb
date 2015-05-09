class Api::ListservsController < Api::ApiController
  def index
    if params[:location_ids].present?
      location_ids = params[:location_ids].map{ |l| l.to_i }
      @listservs = Listserv.joins('inner join listservs_locations')
        .where('listservs_locations.location_id in (?)', location_ids)
    else
      @listservs = Listserv.all
    end
    render json: @listservs
  end
end
