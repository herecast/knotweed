class Api::PublicationsController < Api::ApiController

  # returns list of publications filtered by consumer app (if provided)
  def index
    if params[:consumer_app_uri].present?
      consumer_app = ConsumerApp.find_by_uri params[:consumer_app_uri]
      @publications = consumer_app.publications
    else
      @publications = Publication.all
    end
    render json: @publications
  end

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
