class AddUuidToSubscriptions < ActiveRecord::Migration
  def change
    change_table :subscriptions do |t|
      t.string :key, null: false, index: true
    end
  end
end
