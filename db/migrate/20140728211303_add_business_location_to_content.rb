class AddBusinessLocationToContent < ActiveRecord::Migration
  def change
    add_column :contents, :business_location_id, :integer
  end
end
