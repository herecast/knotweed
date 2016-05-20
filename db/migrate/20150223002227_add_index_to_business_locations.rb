class AddIndexToBusinessLocations < ActiveRecord::Migration
  def change
    add_index :business_locations, :name
    add_index :business_locations, :city
  end
end
