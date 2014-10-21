class Api::PublicationsController < Api::ApiController

  def show
    if params[:id].present?
      @publication = Publication.find(params[:id])
    elsif params[:name].present?
      @publication = Publication.find_by_name(params[:name])
    end
    if @publication.present?
      render :json => @publication
    else
      render text: "No publication found.", status: 500
    end
  end
end
