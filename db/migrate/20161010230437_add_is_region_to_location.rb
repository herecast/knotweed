class AddIsRegionToLocation < ActiveRecord::Migration
  def change
    change_table :locations do |t|
      t.boolean :is_region, default: false
    end
  end
end
