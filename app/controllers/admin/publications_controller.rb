class Admin::PublicationsController < Admin::AdminController
  load_and_authorize_resource 

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
      redirect_to admin_publications_path
    else
      render "edit"
    end
  end

  def create
    if @publication.save
      flash[:notice] = "Created publication with id #{@publication.id}"
    else
      render "new"
    end
  end

  def destroy
    @publication.destroy
  end

  # this is called via ajax for modals in the publication context
  def new_contact
    @publication = Publication.find(params[:id])
    @contact = Contact.new
    render partial: "admin/contacts/form", layout: false
  end

end
