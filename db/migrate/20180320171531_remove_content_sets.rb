class RemoveContentSets < ActiveRecord::Migration
  def up
    drop_table :content_sets
    remove_column :import_jobs, :content_set_id
  end

  def down
    create_table :content_sets do |t|
      t.string :import_method
      t.text :import_method_details
      t.integer :organization_id
      t.string :name
      t.text :description
      t.text :notes
      t.string :status
      t.date :start_date
      t.date :end_date
      t.boolean :ongoing
      t.string :format
      t.string :publishing_frequency
      t.text :developer_notes

      t.timestamps
    end

    add_column :import_jobs, :content_set_id, :integer
  end
end
