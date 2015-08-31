class BusinessLocationsController < ApplicationController
  load_and_authorize_resource

  def index
    @business_locations = BusinessLocation.all # this line just here for debugger target
  end

  def edit
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

  def edit_venue_js
    render partial: "business_locations/partials/form_js", layout: false
  end

  def new
    if params.has_key? :publication_id
      @business_location.publication = Publication.find params[:publication_id]
    end
    respond_to do |format|
      format.html {render 'new'}
      #format.js {render partial: "business_locations/partials/form_js", layout: false}
    end
  end

  def new_venue_js
    @business_location = BusinessLocation.new
    render partial: "business_locations/partials/form_js", layout: false
  end

  def create
    @business_location.created_by = current_user
    #handle html requests from venues pages
    if :html == request.format.symbol
      if @business_location.save
        redirect_to business_locations_path and return
      else
        flash.now[:error] = 'You must have an address, city and state!'
        render 'new'
      end
    else # must be js from embedded form in events calendar
      if @business_location.save
        respond_to do |format|
          format.js
        end
      else
        flash.now[:error] = ' You must enter an address, city and state!'
        render partial: "business_locations/partials/form_js", layout: false
      end
    end
  end

  def update
    @business_location.updated_by = current_user
    #handle html requests from venues pages
    if :html == request.format.symbol
      if @business_location.update_attributes(params[:business_location])
        redirect_to business_locations_path and return
      else
        flash.now[:error] = 'You must have a address, city and state'
        render 'edit'
      end
    else # must be js from embedded form in events calendar
      @business_location.update_attributes!(params[:business_location])
      respond_to do |format|
        format.js
      end
    end
  end

  def destroy
    @business_location.destroy
    respond_to do |format|
      format.html { redirect_to :back }
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
