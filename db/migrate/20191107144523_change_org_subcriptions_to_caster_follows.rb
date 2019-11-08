class ChangeOrgSubcriptionsToCasterFollows < ActiveRecord::Migration[5.1]
  def change
    remove_column :organization_subscriptions, :organization_id, :integer
    rename_table :organization_subscriptions, :caster_follows
  end
end
