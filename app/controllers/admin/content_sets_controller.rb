class Admin::ContentSetsController < Admin::AdminController
  load_and_authorize_resource

  def index
    # if posted, save to session
    if params[:reset]
      session[:content_sets_search] = nil
    elsif params[:q].present?
      session[:content_sets_search] = params[:q]
    end
    @search = ContentSet.search(session[:content_sets_search])
    if session[:content_sets_search].present?
      @content_sets = @search.result(distinct: true)
    else
      @content_sets = ContentSet.all
    end
  end

  def new
  end

  def show
  end

  def edit
  end

  def update
    if @content_set.update_attributes(params[:content_set])
      flash[:notice] = "Successfully updated content set #{@content_set.id}"
      if params[:add_import_job]
        import_job = { :organization_id => @content_set.organization.id, :content_set_id => @content_set.id }
        import_job[:source_path] = @content_set.import_url_path if @content_set.import_url_path.present?
        redirect_to new_admin_import_job_path(:import_job => import_job)
      else
        redirect_to admin_content_sets_path
      end
    else
      render "edit"
    end
  end

  def create
    if @content_set.save
      flash[:notice] = "Created content set with id #{@content_set.id}"
      if params[:add_import_job]
        import_job = { :organization_id => @content_set.organization.id, :content_set_id => @content_set.id }
        import_job[:source_path] = @content_set.import_url_path if @content_set.import_url_path.present?
        redirect_to new_admin_import_job_path(:import_job => import_job)
      else
        redirect_to admin_content_sets_path
      end
    else
      render "new"
    end
  end

  def destroy
    @content_set.destroy
  end


end
