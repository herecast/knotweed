class CreateImportRecords < ActiveRecord::Migration
  def change
    create_table :import_records do |t|
      t.integer :import_job_id
      t.integer :items_imported, default: 0
      t.integer :failures, default: 0

      t.timestamps
    end
    remove_column :import_jobs, :last_run_at
  end
end
