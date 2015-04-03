class CreateLocationsLocations < ActiveRecord::Migration
  def change
    create_table :locations_locations do |t|
      t.integer :parent_id
      t.integer :child_id

      t.timestamps
    end
    add_index :locations_locations, :parent_id
    add_index :locations_locations, :child_id
    add_index :locations_locations, [:parent_id, :child_id]
    add_index :locations_locations, [:child_id, :parent_id]
  end
end
