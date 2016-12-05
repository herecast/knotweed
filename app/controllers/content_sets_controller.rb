class ContentSetsController < ApplicationController
  load_and_authorize_resource

  def index
    # if posted, save to session
    if params[:reset]
      session[:content_sets_search] = nil
    elsif params[:q].present?
      session[:content_sets_search] = params[:q]
    end
    @search = ContentSet.ransack(session[:content_sets_search])
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
    if @content_set.update_attributes(content_set_params)
      flash[:notice] = "Successfully updated content set #{@content_set.id}"
      if params[:add_import_job]
        import_job = { :organization_id => @content_set.organization.id, :content_set_id => @content_set.id }
        import_job[:source_uri] = @content_set.import_url_path if @content_set.import_url_path.present?
        redirect_to new_import_job_path(:import_job => import_job)
      else
        redirect_to content_sets_path
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
        import_job[:source_uri] = @content_set.import_url_path if @content_set.import_url_path.present?
        redirect_to new_import_job_path(:import_job => import_job)
      else
        redirect_to content_sets_path
      end
    else
      render "new"
    end
  end

  def destroy
    @content_set.destroy
    respond_to do |format|
      format.html { redirect_to content_sets_path }
    end
  end

  private

    def content_set_params
      params.require(:content_set).permit(
        :organization_id,
        :name,
        :status,
        :publishing_frequency,
        :description,
        :start_date,
        :end_date,
        :ongoing,
        :import_method,
        :import_method_details,
        :import_priority,
        :import_url_path,
        :import_jobs_attributes,
        :format,
        :notes,
        :developer_notes
        )
    end

end
