class AddConfirmIpToSubscriptions < ActiveRecord::Migration
  def change
    change_table :subscriptions do |t|
      t.string :confirm_ip
    end
  end
end
