class BusinessLocationsController < ApplicationController
  load_and_authorize_resource

  def edit
    respond_to do |format|
      format.js { render partial: "business_locations/partials/form" }
    end
  end

  def new
    if params.has_key? :publication_id
      @business_location.publication = Publication.find params[:publication_id]
    end
    render partial: "business_locations/partials/form", layout: false
  end

  def create
    @business_location.save!
    respond_to do |format|
      format.js
    end
  end

  def update
    @business_location.update_attributes!(params[:business_location])
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @business_location.destroy
    respond_to do |format|
      format.js
    end
  end

end
