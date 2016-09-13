class AddEmailTypeToSubscription < ActiveRecord::Migration
  def change
    change_table :subscriptions do |t|
      t.string :email_type, default: "html"
    end
  end
end
