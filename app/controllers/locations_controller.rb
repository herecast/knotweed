class LocationsController < ApplicationController

  def edit
    @location = Location.find(params[:id])
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
    @location = Location.new(location_params)
    @location.save!
    respond_to do |format|
      format.js
    end
  end

  private

    def location_params
      params.require(:location).permit(
        :city,
        :country,
        :lat,
        :long,
        :state,
        :zip,
        :organization_ids,
        :consumer_active
      )
    end

end
