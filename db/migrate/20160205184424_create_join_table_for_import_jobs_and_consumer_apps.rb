class CreateJoinTableForImportJobsAndConsumerApps < ActiveRecord::Migration
  def up
    create_table :consumer_apps_import_jobs, id: false do |t|
      t.integer :consumer_app_id
      t.integer :import_job_id
      t.timestamps
    end
  end

  def down
    drop_table :consumer_apps_import_jobs
  end
end
