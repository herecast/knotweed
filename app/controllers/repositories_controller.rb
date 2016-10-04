class RepositoriesController < ApplicationController
  load_and_authorize_resource
  respond_to :html

  def index
  end

  def new
  end

  def create
    if @repository.save
      flash[:notice] = "Repository registered."
      redirect_to repositories_path
    else
      render 'new'
    end
  end

  def update
    @repository = Repository.find(params[:id])
    if @repository.update_attributes(repository_params)
      flash[:notice] = "Successfully updated repository."
      redirect_to repositories_path
    else
      render 'edit'
    end
  end

  def destroy
  end

  def edit
  end

  def clear_published_contents
    @repository = Repository.find(params[:id])
    @repository.contents.clear
    respond_to do |format|
      format.js
    end
  end

  private

    def repository_params
      params.require(:repository).permit(
        :dsp_endpoint,
        :name,
        :sesame_endpoint,
        :recommendation_endpoint
      )
    end

end
