class CreateReportJobs < ActiveRecord::Migration
  def change
    create_table :report_jobs do |t|
      t.integer :report_id
      t.text :description
      t.datetime :report_review_date
      t.datetime :report_sent_date
      t.integer :created_by
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
