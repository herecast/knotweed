class AddFeatureNotificationOrgToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :feature_notification_org, :boolean, default: false
    Organization.where(id: [2313,2290]).update_all(feature_notification_org: true)
  end
end
