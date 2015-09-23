class AddStatusToBusinessLocations < ActiveRecord::Migration
  def change
    add_column :business_locations, :status, :string
  end
end
