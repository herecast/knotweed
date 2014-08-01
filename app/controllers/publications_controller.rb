class PublicationsController < ApplicationController
  load_and_authorize_resource except: [:create]

  def index
    # if posted, save to session
    if params[:reset]
      session[:publications_search] = nil
    elsif params[:q].present?
      session[:publications_search] = params[:q]
    end
    @search = Publication.search(session[:publications_search])
    if session[:publications_search].present?
      @publications = @search.result(distinct: true)
    else
      @publications = Publication.all
    end
  end

  def new
  end

  def edit
    @contact = Contact.new
  end

  def update
    # ensure serialized values are set to empty if no fields are passed in via form
    params[:publication][:links] = nil unless params[:publication].has_key? :links
    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Successfully updated publication #{@publication.id}"
      if params[:add_content_set]
        redirect_to new_content_set_path(:content_set => { :publication_id => @publication.id })
      else
        redirect_to publications_path
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
    contact_list = params[:publication].delete("contact_list")
    contact_ids = contact_list.try(:split, ",")

    business_loc_list = params[:publication].delete("business_location_list")
    business_location_ids = business_loc_list.try(:split, ",")

    @publication = Publication.new
    current_ability.attributes_for(:create, Publication).each do |key, value|
      @publication.send("#{key}=", value)
    end
    @publication.attributes = params[:publication]
    authorize! :create, @publication
    if @publication.save
      @publication.update_attribute(:contact_ids, contact_ids) unless contact_ids.nil?
      @publication.update_attribute(:business_location_ids, business_location_ids) unless business_location_ids.nil?
      flash[:notice] = "Created publication with id #{@publication.id}"
      if params[:add_content_set]
        redirect_to new_content_set_path(:content_set => { :publication_id => @publication.id })
      else
        redirect_to publications_path
      end
    else
      render "new"
    end
  end

  def destroy
    @publication.destroy
  end

  def business_location_options
    pub = Publication.find params[:publication_id]
    @business_locations = pub.business_location_options.insert(0, [nil, nil])
    respond_to do |format|
      format.js
    end
  end

end
