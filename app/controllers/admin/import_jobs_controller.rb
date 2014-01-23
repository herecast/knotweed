require 'jobs/jobcontroller'

class Admin::ImportJobsController < Admin::AdminController
  load_and_authorize_resource

  include Jobs::JobController

  respond_to :html
  
  def new
    @content_sets = ContentSet.accessible_by(current_ability)
    if params[:parser_id]
      @import_job.parser = Parser.find(params[:parser_id])
      @import_job.organization = @import_job.parser.organization
    end
  end

  def edit
    @content_sets = ContentSet.accessible_by(current_ability)
  end

  
  def create
    @import_job = ImportJob.new(params[:import_job])
    @import_job.organization = current_user.organization unless @import_job.organization.present?
    if @import_job.save
      @import_job.save_config(params[:parameters])
      flash[:notice] = "Import job saved."
      redirect_to admin_import_jobs_path
    else
      render "new"
    end
  end
  
  def update
    @import_job = ImportJob.find(params[:id])
    if @import_job.update_attributes(params[:import_job])
      @import_job.save_config(params[:parameters])
      flash[:notice] = "Successfully updated import job."
    end
    respond_with(@import_job, location: admin_import_jobs_url)
  end

  def index
    if params[:content_set_id]
      @import_jobs = @import_jobs.unscoped.where(content_set_id: params[:content_set_id])
    end
  end

end
