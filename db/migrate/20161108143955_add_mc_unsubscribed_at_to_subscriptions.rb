class AddMcUnsubscribedAtToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :mc_unsubscribed_at, :datetime, default: nil
  end
end
