class AddStatusToImportJobs < ActiveRecord::Migration
  def change
    add_column :import_jobs, :status, :string
  end
end
