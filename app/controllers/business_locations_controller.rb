class BusinessLocationsController < ApplicationController
  load_and_authorize_resource

  def index
    # if posted, save to session
    if params[:reset]
      session[:business_locations_search] = nil
    elsif params[:q].present?
      session[:business_locations_search] = params[:q]
    end

    @search = BusinessLocation.ransack(session[:business_locations_search])

    @business_locations = @search.result(distinct: true).page(params[:page]).per(100)
  end

  def edit
    if request.xhr?
      render partial: 'business_locations/partials/form_js', layout: false
    else
      if @business_location.geocoded?
        @nearbys = @business_location.nearbys(3)
        @nearbys = @business_location.nearbys(1) if @nearbys.count(:all) > 25
        @nearbys = @business_location.nearbys(0.5) if @nearbys.count(:all) > 25
        @nearbys = @business_location.nearbys(0.25) if @nearbys.count(:all) > 25
        @events_per_venue = [{}]
        @nearbys.each do |v|
          @events_per_venue[v.id] = v.events.count
        end
      end
      @events = @business_location.events
      render 'edit'
    end
  end

  def new
    if params.has_key? :organization_id
      @business_location.organization = Organization.find params[:organization_id]
    end
    if request.xhr?
      render partial: 'business_locations/partials/form_js', layout: false
    else
      render 'new'
    end
  end

  def create
    @business_location.created_by = current_user
    @business_location.status = :approved if request.xhr?
    if @business_location.save
      respond_to do |format|
        format.js
        format.html { redirect_to business_locations_path }
      end
    else
      respond_to do |format|
        format.js { render json: @business_location.errors }
        format.html { render 'new' }
      end
    end
  end

  def update
    @business_location.updated_by = current_user
    if @business_location.update_attributes(business_location_params)
      respond_to do |format|
        format.js
        format.html { redirect_to business_locations_path }
      end
    else
      respond_to do |format|
        format.js { render json: @business_location.errors }
        format.html { render 'edit' }
      end
    end
  end

  def destroy
    # don't allow destroy if it'd leave orphaned records
    if @business_location.business_profile.present? or @business_location.events.present?
      flash[:notice] = "Could not destroy record with associated business profile or evens"
      respond_to do |format|
        format.html { redirect_to business_locations_path }
      end
    else
      @business_location.destroy
      respond_to do |format|
        format.html { redirect_to business_locations_path }
        format.js
      end
    end
  end

  private

  def business_location_params
    params.require(:business_location).permit(:name,
                                              :locate_include_name,
                                              :address,
                                              :city,
                                              :state,
                                              :zip,
                                              :venue_url,
                                              :email,
                                              :phone,
                                              :status,
                                              :organization_id,
                                              hours: []).tap do |attrs|
      if attrs[:hours].respond_to?(:[])
        attrs[:hours].reject! { |h| h.blank? }
      elsif not attrs.has_key? :hours # deal with removing all hours entries
        attrs[:hours] = []
      end
    end
  end
end
