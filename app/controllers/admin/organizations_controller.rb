class Admin::OrganizationsController < Admin::AdminController
  load_and_authorize_resource

  def index
    @search = Organization.search(params[:q])
    if params[:q].present?
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
      redirect_to admin_organizations_path
    else
      render "edit"
    end
  end

  def create
  end

  def destroy
    @organization.destroy
  end


end
