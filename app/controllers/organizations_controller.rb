class OrganizationsController < ApplicationController
  load_and_authorize_resource except: [:create]

  def index
    # if posted, save to session
    if params[:reset]
      session[:organizations_search] = nil
    elsif params[:q].present?
      session[:organizations_search] = params[:q]
    end
    @search = Organization.ransack(session[:organizations_search])
    if session[:organizations_search].present?
      if include_child_organizations?
        return_child_organizations
      else
        if return_news_orgs?
          @organizations = @search.result(distinct: true).where(can_publish_news: true)
        else
          @organizations = @search.result(distinct: true)
        end
      end
    else
      @organizations = Organization
    end
    @organizations = @organizations.includes(:locations).page(params[:page]).per(25)
  end

  def new
    @users = User.all
    get_managers
    if params[:short_form]
      render partial: "organizations/partials/short_form", layout: false
    else
      render 'new'
    end
  end

  def edit
    @users = User.all
    get_managers
    @contact = Contact.new
  end

  def update
    update_business_info if params[:business_location].present?
    if @organization.update_attributes(organization_params)
      flash[:notice] = "Successfully updated organization #{@organization.id}"
      if params[:add_content_set]
        redirect_to new_content_set_path(:content_set => { :organization_id => @organization.id })
      else
        redirect_to organizations_path
      end
    else
      @users = User.all
      get_managers
      render action: "edit"
    end
  end

  # have to put the CanCan authorization code in here directly
  # as we're pulling a special param ("contact_list") from the params
  # list before doing anything and load_and_authorize_resource uses
  # a before filter.
  def create
    contact_list = params[:organization].delete("contact_list")
    contact_ids = contact_list.try(:split, ",")

    business_loc_list = params[:organization].delete("business_location_list")
    business_location_ids = business_loc_list.try(:split, ",")

    # This is part of what cancan does normally in load_resource.
    # It is used to pre load attributes that are part of the ability filter.
    @organization = Organization.new
    current_ability.attributes_for(:create, Organization).each do |key, value|
      @organization.send("#{key}=", value)
    end
    @organization.attributes = organization_params
    authorize! :create, @organization
    if @organization.save
      @organization.update_attribute(:contact_ids, contact_ids) unless contact_ids.nil?
      @organization.update_attribute(:business_location_ids, business_location_ids) unless business_location_ids.nil?
      respond_to do |format|
        format.js
        format.html do
          flash[:notice] = "Created organization with id #{@organization.id}"
          if params[:add_content_set]
            redirect_to new_content_set_path(:content_set => { :organization_id => @organization.id })
          else
            redirect_to organizations_path
          end
        end
      end
    else
      @users = User.all
      get_managers
      render "new"
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

  def business_location_options
    pub = Organization.find params[:organization_id]
    @business_locations = pub.business_location_options.insert(0, [nil, nil])
    respond_to do |format|
      format.js
    end
  end

  protected

    def update_business_info
      business_location = BusinessLocation.find(params[:business_location][:business_location_id])
      business_location.update_attributes(business_location_params)
      business_location.protect_against_blank_hours
      business_location.business_profile.update_attributes(business_profile_params) if params[:business_profile].present?
    end

    def organization_params
      params.require(:organization).permit(
        :name, :logo, :logo_cache, :remove_logo, :organization_id, :twitter_handle,
        :website, :notes, :images_attributes, :parent_id, :location_ids,
        :remote_logo_url, :contact_ids, :org_type,
        :profile_image, :remote_profile_image_url, :remove_profile_image, :profile_image_cache,
        :background_image, :remote_background_image_url, :remove_background_image, :profile_background_image_cache,
        :consumer_app_ids, :can_publish_news, :subscribe_url,
        :description, :banner_ad_override, :pay_rate_in_cents, :profile_title, :pay_directly,
        :can_publish_market, :can_publish_ads, :can_publish_talk, :can_publish_events,
        :profile_ad_override, :biz_feed_active, :ad_sales_agent, :ad_contact_nickname, :ad_contact_fullname,
        :blog_contact_name, :profile_sales_agent,
        :consumer_app_ids => [], :location_ids => [],
        :business_location => [:name, :address, :venue_url, :city,
          :state, :zip, :phone, :email, :hours],
        :business_profile => { :business_category_ids => [] },
        :organization_locations_attributes => [:id, :location_type, :location_id, :_destroy]
      )
    end

    def business_location_params
      params.require(:business_location).permit(
        :name,
        :email,
        :venue_url,
        :address,
        :city,
        :state,
        :zip,
        :phone,
        hours: []
      ).tap do |attrs|
        if attrs[:hours].respond_to?(:[])
          attrs[:hours].reject! { |h| h.blank? }
        end
      end
    end

    def business_profile_params
      params.require(:business_profile).permit(business_category_ids: [])
    end

    def get_managers
      @managers = User.with_role(:manager, @organization)
    end

    def include_child_organizations?
      session[:organizations_search][:include_child_organizations] == "1"
    end

    def return_child_organizations
      # default scope involves ordering by name and Postgres shits the bed if you order
      # by something that isn't included in the select clause
      if return_news_orgs?
        ids_for_parents = @search.result(distinct: true).
          where(can_publish_news: true).
          select(:id, :name).collect(&:id)
      else
        ids_for_parents = @search.result(distinct: true).select(:id, :name).collect(&:id)
      end

      ids_for_children = Organization.get_children(ids_for_parents).select(:id, :name).collect(&:id)
      @organizations = Organization.where(id: ids_for_parents + ids_for_children)
    end

    def return_news_orgs?
      session[:organizations_search]["show_news_publishers"] == "1"
    end
end
