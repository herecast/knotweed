class RemoveTimestampsFromConsumerAppsImportJobs < ActiveRecord::Migration
  def up
    remove_column :consumer_apps_import_jobs, :created_at
    remove_column :consumer_apps_import_jobs, :updated_at
  end

  def down
    add_column :consumer_apps_import_jobs, :updated_at, :string
    add_column :consumer_apps_import_jobs, :created_at, :string
  end
end
