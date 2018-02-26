class Reports::GenerationsController < ApplicationController
  def create
    report = Report.find(params[:report_id])
    @report_job = ReportJob.create_from_report!(report)
    redirect_to edit_report_job_path(@report_job)
  end
end
