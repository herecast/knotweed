class AddModifierInfoToBusinessLocations < ActiveRecord::Migration
  def change
    add_column :business_locations, :created_by, :integer
    add_column :business_locations, :updated_by, :integer
  end
end
