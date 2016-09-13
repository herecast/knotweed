class AddNameToSubscription < ActiveRecord::Migration
  def change
    change_table :subscriptions do |t|
      t.string :name
    end
  end
end
