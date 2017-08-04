class AddLatitudedLongitudeToLocations < ActiveRecord::Migration
  def up
    add_column :locations, :latitude, :float, default: nil
    add_column :locations, :longitude, :float, default: nil

    add_index :locations, [:latitude, :longitude]

    execute <<-SQL
      UPDATE locations
      SET latitude = CAST(lat as float), longitude = CAST(long as float)
      WHERE lat <> '' AND lat IS NOT NULL
      AND long <> '' AND long IS NOT NULL
    SQL

    remove_column :locations, :lat
    remove_column :locations, :long
  end

  def down
    add_column :locations, :lat, :string, default: nil
    add_column :locations, :long, :string, default: nil

    execute <<-SQL
      UPDATE locations
      SET lat = CAST(latitude as character varying), long = CAST(longitude as character varying)
      WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
    SQL

    remove_column :locations, :latitude
    remove_column :locations, :longitude
  end
end
