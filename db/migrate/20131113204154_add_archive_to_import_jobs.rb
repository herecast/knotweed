class AddArchiveToImportJobs < ActiveRecord::Migration
  def change
    add_column :import_jobs, :archive, :boolean, default: false, null: false
  end
end
