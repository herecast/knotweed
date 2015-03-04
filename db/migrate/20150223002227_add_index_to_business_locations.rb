class AddIndexToBusinessLocations < ActiveRecord::Migration
  def change
    add_index :business_locations, :name
  end
end
