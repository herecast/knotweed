class ReportJobs::RunsController < ApplicationController
  def create
    @report_job = ReportJob.find(params[:report_job_id])
    is_review = params[:review_type] == 'review' ? true : false
    @report_job.run_report_job(is_review)
    flash[:notice] = "Sent report_job #{@report_job.id} to Jasper as #{is_review ? "review" : "final"}"
    redirect_to report_jobs_path
  end
end
