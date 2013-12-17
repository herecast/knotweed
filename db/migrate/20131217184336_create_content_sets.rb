class CreateContentSets < ActiveRecord::Migration
  def change
    create_table :content_sets do |t|
      t.string :import_method
      t.text :import_method_details
      t.integer :publication_id
      t.string :name
      t.text :description
      t.text :notes
      t.string :status

      t.timestamps
    end

    add_column :publications, :parent_id, :integer
    add_column :import_jobs, :content_set_id, :integer

  end
end
