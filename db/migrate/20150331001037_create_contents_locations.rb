class CreateContentsLocations < ActiveRecord::Migration
  def change
    create_table :contents_locations do |t|
      t.integer :content_id
      t.integer :location_id

      t.timestamps
    end
    add_index :contents_locations, :content_id
    add_index :contents_locations, :location_id
    add_index :contents_locations, [:content_id, :location_id,]
    add_index :contents_locations, [:location_id, :content_id]
  end
end
