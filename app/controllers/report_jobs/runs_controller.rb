class ReportJobs::RunsController < ApplicationController
  def create
    @report_job = ReportJob.find(params[:report_job_id])
    PaymentReportJob.perform_later(@report_job)
    flash[:notice] = "Queued report job for #{@report_job.report_job_recipients.count} recipients"
    redirect_to report_jobs_path
  end
end
