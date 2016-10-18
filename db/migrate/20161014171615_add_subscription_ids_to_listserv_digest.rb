class AddSubscriptionIdsToListservDigest < ActiveRecord::Migration
  def change
    add_column :listserv_digests, :subscription_ids, :integer, array: true, default: []
  end
end
