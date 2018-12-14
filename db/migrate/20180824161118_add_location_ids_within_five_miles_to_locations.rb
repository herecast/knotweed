class AddLocationIdsWithinFiveMilesToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :location_ids_within_five_miles, :integer, array: true, default: []
  end
end
