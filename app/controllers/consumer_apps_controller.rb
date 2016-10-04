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
    if @consumer_app.update_attributes(consumer_app_params)
      flash[:notice] = "Consumer app updated."
      redirect_to consumer_apps_path
    else
      render 'edit'
    end
  end

  private
    
    def consumer_app_params
      params.require(:consumer_app).permit(
        :name,
        :repository_id,
        :uri,
        :organization_ids,
        :import_job_ids
      )
    end

end
