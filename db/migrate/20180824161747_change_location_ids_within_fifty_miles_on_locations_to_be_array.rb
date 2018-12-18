# frozen_string_literal: true

class ChangeLocationIdsWithinFiftyMilesOnLocationsToBeArray < ActiveRecord::Migration
  def up
    remove_column :locations, :location_ids_within_fifty_miles
    add_column :locations, :location_ids_within_fifty_miles, :integer, array: true, default: []
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
