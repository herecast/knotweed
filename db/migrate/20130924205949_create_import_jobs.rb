class CreateImportJobs < ActiveRecord::Migration
  def change
    create_table :import_jobs do |t|
      t.integer :parser_id
      t.string :name
      t.text :config
      t.timestamp :last_run_at
      t.string :source_path
      t.string :type
      t.integer :organization_id

      t.timestamps
    end
  end
end
