class LocationsController < ApplicationController
  load_and_authorize_resource

  def edit
    respond_to do |format|
      format.js { render partial: "locations/form" }
    end
  end

  def new
    respond_to do |format|
      format.js { render partial: "locations/form" }
    end
  end

  def create
    @location.save!
    respond_to do |format|
      format.js
    end
  end

  def update
    @location.update_attributes!(params[:location])
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @location.destroy
    respond_to do |format|
      format.js
    end
  end

end
