class BusinessProfilesController < ApplicationController
  load_and_authorize_resource except: [:create]

  def index
    # if posted, save to session
    if params[:reset]
      session[:business_profiles_search] = nil
    elsif params[:q].present?
      params[:q][:id_in] = params[:q][:id_in].split(',').map { |s| s.strip } if params[:q][:id_in].present?
      session[:business_profiles_search] = params[:q]
    end

    @search = BusinessProfile.ransack(session[:business_profiles_search])
    @archived = session[:business_profiles_search][:archived_eq] if session[:business_profiles_search].present? and session[:business_profiles_search][:archived_eq].present?

    if session[:business_profiles_search].present?
      @business_profiles = @search.result(distinct: true).page(params[:page]).per(100)
      @business_profiles = @business_profiles.accessible_by(current_ability)
    else
      @business_profiles = []
    end
  end

  def show
  end

  def update
    if @business_profile.update_attributes!(params[:business_profile])
      flash[:notice] = "Successfully updated business #{@business_profile.business_location.name}"
      redirect_to form_submit_redirect_path(@business_profile.id)
    else
      render 'edit'
    end
  end

  def create
    @business_profile = BusinessProfile.new(params[:business_profile])
    authorize! :create, @business_profile
    if @business_profile.save
      flash[:notice] = "Created business profile with id #{@business_profile.id}"
      redirect_to form_submit_redirect_path(@business_profile.id)
    else
      render 'new'
    end
  end

  def new
    @business_profile.build_business_location if @business_profile.business_location.nil?
  end

  def edit
    @users = User.all

    if @business_profile.claimed?
      @business_profile.content.images.build if @business_profile.content.images.empty?
      authorize! :edit, @business_profile
      if Role.where(resource_type: 'Organization', resource_id: @business_profile.content.organization.id).present?
        @managers = Role.where(resource_type: 'Organization', resource_id: @business_profile.content.organization.id).first.users
      end
    else
      flash[:alert] = "Business must be claimed to edit"
      redirect_to business_profiles_path
    end
  end

  private

    def form_submit_redirect_path(id=nil)
      if params[:continue_editing]
        edit_business_profile_path(id)
      elsif params[:create_new]
        new_business_profile_path
      elsif params[:next_record]
        edit_business_profile_path(params[:next_record_id], index: params[:index], page: params[:page])
      else
        business_profiles_path
      end
    end
end
