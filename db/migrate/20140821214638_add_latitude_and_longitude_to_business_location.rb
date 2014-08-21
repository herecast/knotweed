class AddLatitudeAndLongitudeToBusinessLocation < ActiveRecord::Migration
  def change
    add_column :business_locations, :latitude, :float
    add_column :business_locations, :longitude, :float
  end
end
