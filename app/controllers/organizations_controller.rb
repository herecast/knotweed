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
      @organizations = @search.result(distinct: true)
    else
      @organizations = Organization
    end
    @organizations = @organizations.includes(:locations).page(params[:page]).per(25)
  end

  def new
    if params[:short_form]
      render partial: "organizations/partials/short_form", layout: false
    else
      render 'new'
    end
  end

  def edit
    @contact = Contact.new
  end

  def update
    if @organization.update_attributes(params[:organization])
      flash[:notice] = "Successfully updated organization #{@organization.id}"
      if params[:add_content_set]
        redirect_to new_content_set_path(:content_set => { :organization_id => @organization.id })
      else
        redirect_to organizations_path
      end
    else
      render "edit"
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

    @organization = Organization.new
    current_ability.attributes_for(:create, Organization).each do |key, value|
      @organization.send("#{key}=", value)
    end
    @organization.attributes = params[:organization]
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
      render "new"
    end
  end

  def destroy
    @organization.destroy
  end

  def business_location_options
    pub = Organization.find params[:organization_id]
    @business_locations = pub.business_location_options.insert(0, [nil, nil])
    respond_to do |format|
      format.js
    end
  end

end
