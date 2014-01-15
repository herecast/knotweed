class Admin::PublicationsController < Admin::AdminController
  load_and_authorize_resource except: [:create]

  def index
    @search = Publication.search(params[:q])
    if params[:q].present?
      @publications = @search.result(distinct: true)
    else
      @publications = Publication.all
    end
  end

  def new
  end

  def show
  end

  def edit
    @contact = Contact.new
  end

  def update
    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Successfully updated publication #{@publication.id}"
      if params[:add_content_set]
        redirect_to new_admin_content_set_path(:content_set => { :publication_id => @publication.id })
      else
        redirect_to admin_publications_path
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
    @publication = Publication.new
    current_ability.attributes_for(:create, Publication).each do |key, value|
      @publication.send("#{key}=", value)
    end
    @publication.attributes = params[:publication]
    authorize! :create, @publication
    if @publication.save
      @publication.update_attribute(:contact_ids, contact_ids) unless contact_ids.nil?
      flash[:notice] = "Created publication with id #{@publication.id}"
      if params[:add_content_set]
        redirect_to new_admin_content_set_path(:content_set => { :publication_id => @publication.id })
      else
        redirect_to admin_publications_path
      end
    else
      render "new"
    end
  end

  def destroy
    @publication.destroy
  end

end
