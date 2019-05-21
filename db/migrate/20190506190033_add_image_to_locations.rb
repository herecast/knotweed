class AddImageToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :image, :string
  end
end
