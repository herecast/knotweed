class ConsumerAppsController < ApplicationController
  load_and_authorize_resource
  def index
  end

  def new
  end

  def create
    if @consumer_app.save
      flash[:notice] = "Consumer app registered."
      redirect_to consumer_apps_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    @consumer_app = ConsumerApp.find params[:id]
    if @consumer_app.update_attributes params[:consumer_app]
      flash[:notice] = "Consumer app updated."
      redirect_to consumer_apps_path
    else
      render 'edit'
    end
  end
end
