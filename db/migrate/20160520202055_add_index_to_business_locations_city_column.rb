class AddIndexToBusinessLocationsCityColumn < ActiveRecord::Migration
  def change
    add_index :business_locations, :city
  end
end
