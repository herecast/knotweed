class AddIndexToImagesTable < ActiveRecord::Migration
  def change
    add_index :images, [:imageable_type, :imageable_id]
  end
end
