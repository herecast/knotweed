class AddColumnsToReportJobRecipients < ActiveRecord::Migration
  def change
    add_column :report_job_recipients, :report_review_date, :datetime
    add_column :report_job_recipients, :report_sent_date, :datetime
    add_column :report_job_recipients, :jasper_review_response, :text
    add_column :report_job_recipients, :jasper_sent_response, :text
    add_column :report_job_recipients, :run_failed, :boolean, default: false
  end
end
