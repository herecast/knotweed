# frozen_string_literal: true

class AddDefaultLocationToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :default_location, :boolean, default: false
    Location.find_by_slug('hartford-vt')&.update_attribute(
      :default_location, true
    )
  end
end
