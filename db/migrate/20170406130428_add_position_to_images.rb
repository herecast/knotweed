class AddPositionToImages < ActiveRecord::Migration
  def change
    add_column :images, :position, :integer, default: 0
  end
end
