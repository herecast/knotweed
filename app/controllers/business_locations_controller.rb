class BusinessLocationsController < ApplicationController
  load_and_authorize_resource

  def index
    @business_locations = BusinessLocation.all # this line just here for debugger target
  end

  def edit
    respond_to do |format|
      format.js { render partial: "business_locations/partials/form" }
    end
  end

  def new
    if params.has_key? :publication_id
      @business_location.publication = Publication.find params[:publication_id]
    end
    if (params[:test] == 'html')
      respond_to do |format|
        format.html {render 'new'}
      end
    else
      respond_to do |format|
        format.js {render partial: "business_locations/partials/form", layout: false}
      end
    end

  end

  def create
    @business_location.created_by = current_user
    @business_location.save!
    #if @business_location.save
    #  redirect_to business_locations_path and return
    #end
    respond_to do |format|
      format.js
    end
  end

  def update
    @business_location.updated_by = current_user
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

  def edit_venue
    if @business_location.geocoded?
      @nearbys = @business_location.nearbys(3)
      @nearbys = @business_location.nearbys(1) if @nearbys.count > 25
      @nearbys = @business_location.nearbys(0.5) if @nearbys.count > 25
      @nearbys = @business_location.nearbys(0.25) if @nearbys.count > 25
      @events_per_venue = [{}]
      @nearbys.each do |v|
        @events_per_venue[v.id] = v.events.count
      end
    end
    @events = @business_location.events

    render 'edit'
  end

  def add_venue
    @business_location = BusinessLocation.new
    render 'new'
  end
end
