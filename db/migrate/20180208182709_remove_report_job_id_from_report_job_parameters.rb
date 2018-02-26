class RemoveReportJobIdFromReportJobParameters < ActiveRecord::Migration
  def change
    remove_column :report_job_params, :report_job_id 
  end
end
