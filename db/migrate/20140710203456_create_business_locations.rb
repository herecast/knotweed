class CreateBusinessLocations < ActiveRecord::Migration
  def change
    create_table :business_locations do |t|
      t.string :name
      t.integer :organization_id
      t.string :address
      t.string :phone
      t.string :email
      t.string :hours

      t.timestamps
    end
  end
end
