class ReportJobs::RunsController < ApplicationController
  def create
    @report_job = ReportJob.find(params[:report_job_id])
    is_review = params[:review_type] == 'review' ? true : false
    results = @report_job.run_report_job(is_review)
    flash[:notice] = "Successfully queued #{results[:successes]} #{is_review ? "review" : "final"} runs on Jasper; failed to queue #{results[:failures]}"
    redirect_to report_jobs_path
  end
end
