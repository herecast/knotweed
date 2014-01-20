class Admin::OrganizationsController < Admin::AdminController
  load_and_authorize_resource except: [:create]

  def index
    # if posted, save to session
    if params[:q].present?
      session[:organizations_search] = params[:q]
    end
    @search = Organization.search(session[:organizations_search])
    if session[:organizations_search].present?
      @organizations = @search.result(distinct: true)
    else
      @organizations = Organization.all
    end
  end

  def new
  end

  def show
  end

  def edit
  end

  def update
    if @organization.update_attributes(params[:organization])
      flash[:notice] = "Successfully updated organization #{@organization.id}"
      if params[:add_publication]
        redirect_to new_admin_publication_path(:publication => { :organization_id => @organization.id })
      else
        redirect_to admin_organizations_path
      end
    else
      render "edit"
    end
  end

  def create
    contact_list = params[:organization].delete("contact_list")
    contact_ids = contact_list.try(:split, ",")
    @organization = Organization.new
    current_ability.attributes_for(:create, Organization).each do |key, value|
      @organization.send("#{key}=", value)
    end
    @organization.attributes = params[:organization]
    authorize! :create, @organization
    if @organization.save
      @organization.update_attribute(:contact_ids, contact_ids) unless contact_ids.nil?
      flash[:notice] = "Created organization with id #{@organization.id}"
      if params[:add_publication]
        redirect_to new_admin_publication_path(:publication => { :organization_id => @organization.id })
      else
        redirect_to admin_organizations_path
      end
    else
      render "new"
    end
  end
  

  def destroy
    @organization.destroy
  end


end
