class CreateTriples < ActiveRecord::Migration
  def change
    create_table :triples do |t|
      t.integer :dataset_id
      t.string :resource_class
      t.integer :resource_id
      t.string :resource_text
      t.string :predicate
      t.string :object_type
      t.string :object_class
      t.integer :object_resource_id
      t.string :object_resource_text
      t.string :realm

      t.timestamps
    end
  end
end
