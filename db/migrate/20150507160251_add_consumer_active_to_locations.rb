class AddConsumerActiveToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :consumer_active, :boolean, default: false
  end
end
