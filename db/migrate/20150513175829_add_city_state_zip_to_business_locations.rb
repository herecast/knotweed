class AddCityStateZipToBusinessLocations < ActiveRecord::Migration
  def change
    add_column :business_locations, :city, :string
    add_column :business_locations, :state, :string
    add_column :business_locations, :zip, :string
  end
end
