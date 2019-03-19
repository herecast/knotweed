# frozen_string_literal: true

class OrganizationsController < ApplicationController
  load_and_authorize_resource except: [:create]

  def index
    # if posted, save to session
    if params[:reset]
      session[:organizations_search] = nil
    elsif params[:q].present?
      params[:q].delete(:pay_for_content_true) if params[:q][:pay_for_content_true] == '0'
      session[:organizations_search] = params[:q]
    end
    @search = Organization.ransack(session[:organizations_search])
    if session[:organizations_search].present?
      if include_child_organizations?
        return_child_organizations
      else
        @organizations = if return_news_orgs?
                           @search.result(distinct: true).where(can_publish_news: true)
                         else
                           @search.result(distinct: true)
                         end
      end
    else
      @organizations = Organization
    end
    @organizations = @organizations.includes(:locations).page(params[:page]).per(25)
  end

  def new
    if params[:short_form]
      render partial: 'organizations/partials/short_form', layout: false
    else
      render 'new'
    end
  end

  def edit; end

  def update
    if @organization.update_attributes(organization_params)
      flash[:notice] = "Successfully updated organization #{@organization.id}"
      redirect_to form_submit_redirect_path(@organization.id)
    else
      render action: 'edit'
    end
  end

  # have to put the CanCan authorization code in here directly
  # as we're pulling a special param ("contact_list") from the params
  # list before doing anything and load_and_authorize_resource uses
  # a before filter.
  def create
    business_loc_list = params[:organization].delete('business_location_list')
    business_location_ids = business_loc_list.try(:split, ',')

    # This is part of what cancan does normally in load_resource.
    # It is used to pre load attributes that are part of the ability filter.
    @organization = Organization.new
    current_ability.attributes_for(:create, Organization).each do |key, value|
      @organization.send("#{key}=", value)
    end
    @organization.attributes = organization_params
    authorize! :create, @organization
    if @organization.save
      @organization.update_attribute(:business_location_ids, business_location_ids) unless business_location_ids.nil?
      respond_to do |format|
        format.js
        format.html do
          flash[:notice] = "Created organization with id #{@organization.id}"
          redirect_to form_submit_redirect_path(@organization.id)
        end
      end
    else
      render 'new'
    end
  end

  def destroy
    @organization.destroy
    respond_to do |format|
      format.js
      format.html do
        redirect_to organizations_path
      end
    end
  end

  protected

  def form_submit_redirect_path(id = nil)
    if params[:continue_editing]
      edit_organization_path(id)
    else
      organizations_path
    end
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :organization_id,
      :twitter_handle,
      :website,
      :notes,
      :images_attributes,
      :parent_id,
      :location_ids,
      :org_type,
      :profile_image,
      :remote_profile_image_url,
      :remove_profile_image,
      :profile_image_cache,
      :background_image,
      :remote_background_image_url,
      :remove_background_image,
      :desktop_image,
      :remote_desktop_image_url,
      :remove_desktop_image,
      :profile_background_image_cache,
      :can_publish_news,
      :description,
      :banner_ad_override,
      :pay_rate_in_cents,
      :pay_directly,
      :biz_feed_active,
      :ad_sales_agent,
      :ad_contact_nickname,
      :ad_contact_fullname,
      :profile_sales_agent,
      :certified_storyteller,
      :embedded_ad,
      :services,
      :contact_card_active,
      :description_card_active,
      :hours_card_active,
      :pay_for_content,
      :special_link_url,
      :special_link_text,
      :certified_social,
      :archived,
      :calendar_view_first,
      :calendar_card_active,
      :digest_id,
      location_ids: [],
      organization_locations_attributes: %i[
        id
        location_type
        location_id
        _destroy
      ]
    )
  end

  def business_profile_params
    params.require(:business_profile).permit(business_category_ids: [])
  end

  def include_child_organizations?
    session[:organizations_search][:include_child_organizations] == '1'
  end

  def return_child_organizations
    # default scope involves ordering by name and Postgres shits the bed if you order
    # by something that isn't included in the select clause
    if return_news_orgs?
      ids_for_parents = @search.result(distinct: true)
                               .where(can_publish_news: true)
                               .select(:id, :name).collect(&:id)
    else
      ids_for_parents = @search.result(distinct: true).select(:id, :name).collect(&:id)
    end

    ids_for_children = Organization.get_children(ids_for_parents).select(:id, :name).collect(&:id)
    @organizations = Organization.where(id: ids_for_parents + ids_for_children)
  end

  def return_news_orgs?
    session[:organizations_search]['show_news_publishers'] == '1'
  end
end
