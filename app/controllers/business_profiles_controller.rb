# frozen_string_literal: true

class BusinessProfilesController < ApplicationController
  load_and_authorize_resource except: [:create]
  before_action :check_for_claim, only: %i[edit update]

  def index
    # if posted, save to session
    if params[:reset]
      session[:business_profiles_search] = nil
    elsif params[:q].present?
      params[:q][:id_in] = params[:q][:id_in].split(',').map(&:strip) if params[:q][:id_in].present?
      session[:business_profiles_search] = params[:q]
    end

    @search = BusinessProfile.ransack(session[:business_profiles_search])
    @archived = session.try(:[], :business_profiles_search).try(:[], :archived_eq)

    if session[:business_profiles_search].present?
      @business_profiles = @search.result(distinct: true).page(params[:page]).per(100)
      @business_profiles = @business_profiles
    else
      @business_profiles = []
    end
  end

  def show; end

  def update
    if @business_profile.update_attributes(business_profile_params)
      flash[:notice] = "Successfully updated business #{@business_profile.business_location.name}"
      redirect_to form_submit_redirect_path(@business_profile.id)
    else
      @managers = User.with_role(:manager, @business_profile.content.organization)
      render 'edit'
    end
  end

  def create
    @business_profile = BusinessProfile.new(business_profile_params)
    authorize! :create, @business_profile
    if @business_profile.save
      CreateBusinessProfileRelationship.call(
        business_profile: @business_profile,
        org_name: params[:business_profile][:business_location_attributes][:name]
      )

      flash[:notice] = "Created business profile with id #{@business_profile.id}"
      redirect_to form_submit_redirect_path(@business_profile.id)
    else
      render 'new'
    end
  end

  def new
    @business_profile.build_business_location if @business_profile.business_location.nil?
    @business_profile.build_content
  end

  def edit
    @managers = User.with_role(:manager, @business_profile.content.organization)
    @business_profile.content.images.build if @business_profile.content.images.empty?
    authorize! :edit, @business_profile
  end

  private

  def business_profile_params
    params.require(:business_profile).permit(
      :content_attributes,
      :business_location,
      business_location_attributes: [
        :name,
        :address,
        :venue_url,
        :city,
        :state,
        :zip,
        :phone,
        :email,
        :id,
        hours: []
      ],
      content_attributes: [
        :id,
        :raw_content,
        images_attributes: %i[
          id
          image
          remove_image
        ],
        organization_attributes: %i[
          id
          parent_id
          logo
          remove_logo
        ]
      ]
    )
  end

  def form_submit_redirect_path(id = nil)
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

  def check_for_claim
    unless @business_profile.claimed?
      flash[:alert] = 'Business must be claimed to edit'
      redirect_to business_profiles_path
    end
  end
end
