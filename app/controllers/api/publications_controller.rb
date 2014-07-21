class Api::PublicationsController < Api::ApiController

  def show
    @publication = Publication.find(params[:id])
    render :json => @publication
  end
end
