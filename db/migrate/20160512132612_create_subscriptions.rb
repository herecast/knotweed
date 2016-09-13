class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :user, index: true, foreign_key: true
      t.references :listserv, index: true, foreign_key: true
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at
      t.boolean :blacklist, default: false
      t.string :subscription_details
      t.string :source
      t.string :email, null: false
      t.string :confirmation_details

      t.timestamps null: false
    end
  end
end
