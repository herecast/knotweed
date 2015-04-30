class Api::ListservsController < Api::ApiController
  def index
    @listservs = Listserv.all
    render json: @listservs
  end
end
