class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :title
      t.string :report_path
      t.string :output_formats_review
      t.string :output_formats_send
      t.string :output_file_name
      t.string :repository_folder
      t.boolean :overwrite_files, default: false
      t.text :notes
      t.integer :created_by
      t.integer :updated_by

      t.timestamps null: false
    end
  end
end
