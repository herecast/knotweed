class LocationsController < ApplicationController
  load_and_authorize_resource

  def index
    # if posted, save to session
    if params[:reset]
      session[:locations_search] = nil
    elsif params[:q].present?
      session[:locations_search] = params[:q]
    end

    @search = Location.order('city ASC').ransack(session[:locations_search])

    @locations = @search.result(distinct: true).page(params[:page]).per(100)
  end

  def edit
    render 'edit'
  end

  def new
    render 'new'
  end

  def create
    if @location.save
      respond_to do |format|
        format.html { redirect_to locations_path }
      end
    else
      respond_to do |format|
        format.html { render 'new' }
      end
    end
  end

  def update
    if @location.update_attributes(location_params)
      respond_to do |format|
        format.html { redirect_to locations_path }
      end
    else
      respond_to do |format|
        format.html { render 'edit' }
      end
    end
  end

  private

    def location_params
      params.require(:location).permit(
        :city,
        :state,
        :zip,
        :slug,
        :county,
        :latitude,
        :longitude,
        :consumer_active,
        :is_region
      )
    end
end
