class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :zip
      t.string :city
      t.string :state
      t.string :county
      t.string :lat
      t.string :long

      t.timestamps
    end

    create_table :locations_publications do |t|
      t.integer :location_id
      t.integer :publication_id
      t.timestamps
    end
  end
end
