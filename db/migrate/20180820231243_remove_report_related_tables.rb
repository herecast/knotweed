class RemoveReportRelatedTables < ActiveRecord::Migration
  def up
    drop_table :report_job_recipients
    drop_table :report_recipients
    drop_table :report_job_params
    drop_table :report_jobs
    drop_table :report_params
    drop_table :reports
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot restore the report related tables that have been dropped"
  end
end
