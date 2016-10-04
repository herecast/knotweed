require 'jobs/jobcontroller'

class ImportJobsController < ApplicationController
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
    @import_job = ImportJob.new(import_job_params)
    if @import_job.save
      subscribe_user(@import_job)
      @import_job.save_config(params[:parameters])
      flash[:notice] = "Import job saved."
      redirect_to import_jobs_path
    else
      render "new"
    end
  end
  
  def update
    @import_job = ImportJob.find(params[:id])
    if @import_job.update_attributes(import_job_params)
      @import_job.save_config(params[:parameters])
      flash[:notice] = "Successfully updated import job."
    end
    respond_with(@import_job, location: import_jobs_url)
  end

  def index
    if params[:content_set_id]
      @import_jobs = @import_jobs.unscoped.where(content_set_id: params[:content_set_id])
    end
  end

  def stop_ongoing_job
    @import_job = ImportJob.find(params[:id])
    @import_job.update_attribute :stop_loop, true
    respond_to do |format|
      format.js
    end
  end

  private

    def import_job_params
      params.require(:import_job).permit(
        :config,
        :name,
        :parser_id,
        :source_path,
        :job_type,
        :organization_id,
        :frequency,
        :archive,
        :content_set_id,
        :run_at,
        :stop_loop,
        :automatically_publish,
        :repository_id,
        :publish_method,
        :job_type,
        :consumer_app_ids
        )
    end

end
