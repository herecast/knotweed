class AddDeletedAtToOrganizationSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :organization_subscriptions, :deleted_at, :datetime
  end
end
