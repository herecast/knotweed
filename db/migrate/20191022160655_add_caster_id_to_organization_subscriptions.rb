class AddCasterIdToOrganizationSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :organization_subscriptions, :caster_id, :integer
    add_index :organization_subscriptions, :caster_id
    OrganizationSubscription.find_each do |org_subscription|
      caster_id = org_subscription.organization.user_id
      if caster_id.present?
        org_subscription.update_attribute(:caster_id, caster_id)
      end
    end
  end
end
