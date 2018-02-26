class CreateReportJobRecipients < ActiveRecord::Migration
  def change
    create_table :report_job_recipients do |t|
      t.integer :report_job_id
      t.integer :report_recipient_id
      t.integer :created_by
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
