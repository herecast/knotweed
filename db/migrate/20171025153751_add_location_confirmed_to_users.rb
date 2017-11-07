class AddLocationConfirmedToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.column :location_confirmed, :boolean, default: false
    end
  end
end
