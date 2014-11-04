class AddVenueUrlToBusinessLocation < ActiveRecord::Migration
  def change
    add_column :business_locations, :venue_url, :string
  end
end
