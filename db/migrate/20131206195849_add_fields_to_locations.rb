class AddFieldsToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :parent_id, :integer
    add_column :locations, :region_id, :integer
    add_column :locations, :country, :string, limit: 128
    add_column :locations, :link_name, :string
    add_index :locations, :link_name
    add_column :locations, :link_name_full, :string
    add_column :locations, :status, :integer, limit: 1, default: 1, null: false
    add_index :locations, :status
    add_column :locations, :usgs_id, :string, limit: 128
    add_index :locations, :usgs_id
    add_index :locations, :state
  end
end
