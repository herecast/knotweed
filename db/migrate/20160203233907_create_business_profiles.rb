class CreateBusinessProfiles < ActiveRecord::Migration
  def up
    create_table :business_profiles do |t|
      t.integer :business_location_id
      t.boolean :has_retail_location, default: true

      t.timestamps
    end
    change_column :business_locations, :hours, :text
    add_column :business_locations, :service_radius, :decimal
  end

  def down
    drop_table :business_profiles
    change_column :business_locations, :hours, :string
    remove_column :business_locations, :service_radius
  end
end
