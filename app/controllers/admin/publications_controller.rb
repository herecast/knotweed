class Admin::PublicationsController < Admin::AdminController
  load_and_authorize_resource 

  def index
    @search = Publication.search(params[:q])
    if params[:q].present?
      @publications = @search.result(distinct: true)
    else
      @publications = Publication.all
    end
  end

  def new
  end

  def show
  end

  def edit
  end

  def update
  end

  def create
  end

  def destroy
  end
end
