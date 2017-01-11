class RemoveConsumerAppsImportJobsJoinsTable < ActiveRecord::Migration
  def up
    drop_table :consumer_apps_import_jobs
  end

  def down
    create_table :consumer_apps_import_jobs, id: false, force: :cascade do |t|
      t.integer "consumer_app_id", limit: 8
      t.integer "import_job_id",   limit: 8
    end
  end
end
