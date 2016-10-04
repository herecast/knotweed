require 'jobs/jobcontroller'

class PublishJobsController < ApplicationController
  load_and_authorize_resource

  include Jobs::JobController

  # ajax method responds to queries that serialize the form for creating
  # publish jobs
  def contents_count
    @count = Content.contents_query(params).count
    respond_to do |format|
      format.js
    end
  end

  def job_contents_count
    @publish_job = PublishJob.find(params[:id])
    render layout: false
  end

  def create
    # this is a hack -- I'm including the field on the page to make error display simpler
    params[:publish_job].delete(:query_params)
    @publish_job = PublishJob.new()
    @publish_job.query_params = {}
    PublishJob::QUERY_PARAMS_FIELDS.each do |key|
      @publish_job.query_params[key.to_sym] = params[key]
    end

    if @publish_job.update_attributes(publish_job_params)
      subscribe_user(@publish_job)
      redirect_to publish_jobs_path
    else
      flash.now[:error] = "Could not save publish job"
      render "new"
    end
  end

  def update
    # this is a hack -- I'm including the field on the page to make error display simpler
    params[:publish_job].delete(:query_params)
    @publish_job = PublishJob.find(params[:id])
    PublishJob::QUERY_PARAMS_FIELDS.each do |key|
      @publish_job.query_params[key.to_sym] = params[key]
    end
    if @publish_job.save and @publish_job.update_attributes(publish_job_params)
      redirect_to publish_jobs_path
    else
      flash.now[:error] = "Could not save publish job"
      render "edit"
    end
  end

  def file_archive
    @publish_job = PublishJob.find(params[:id])
    unless @publish_job.file_archive.nil?
      send_file @publish_job.file_archive
    else
      raise ActionController::RoutingError.new("Not Found")
    end
  end

  private

    def publish_job_params
      params.require(:publish_job).permit(
        :name,
        :description,
        :publish_method,
        :run_at,
        :frequency,
        :query_params
      )
    end

end
