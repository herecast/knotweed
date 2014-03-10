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
    @publish_job = PublishJob.new()
    @publish_job.query_params = {}
    PublishJob::QUERY_PARAMS_FIELDS.each do |key|
      @publish_job.query_params[key.to_sym] = params[key]
    end

    if @publish_job.update_attributes(params[:publish_job])
      subscribe_user(@publish_job)
      redirect_to publish_jobs_path
    else
      flash.now[:error] = "Could not save publish job"
      render action: "new"
    end
  end

  def update
    @publish_job = PublishJob.find(params[:id])
    PublishJob::QUERY_PARAMS_FIELDS.each do |key|
      @publish_job.query_params[key.to_sym] = params[key]
    end
    if @publish_job.update_attributes(params[:publish_job])
      redirect_to publish_jobs_path
    else
      flash.now[:error] = "Could not save publish job"
      render action: "edit"
    end
  end

end
