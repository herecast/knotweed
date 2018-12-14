class AddLocationIdsWithinFiftyMilesToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :location_ids_within_fifty_miles, :string
  end
end
