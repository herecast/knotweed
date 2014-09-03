class AddAutomaticallyPublishToImportJobs < ActiveRecord::Migration
  def change
    add_column :import_jobs, :automatically_publish, :boolean, default: false
    add_column :import_jobs, :repository_id, :integer
    add_column :import_jobs, :publish_method, :string
  end
end
