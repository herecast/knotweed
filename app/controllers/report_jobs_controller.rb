class ReportJobsController < ApplicationController
  load_and_authorize_resource

  def index
    @search = ReportJob.ransack(params[:q])
    @report_jobs = @search.result(distinct: true).order('created_at DESC').
      includes(:report).
      page(params[:page]).per(25)
  end

  def new
  end

  def create
    if @report_job.save
      flash[:notice] = "Created report_job with id #{@report_job.id}"
      redirect_to report_jobs_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @report_job.update_attributes(report_job_params)
      flash[:notice] = "Successfully updated report_job #{@report_job.id}"
      redirect_to report_jobs_path
    else
      render 'edit'
    end
  end

  private

  def report_job_params
    params.require(:report_job).permit(
      :report_id,
      :description,
      report_job_params_attributes: [:param_name, :param_value, :_destroy, :id]
    )
  end
end
