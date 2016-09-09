class AddPublishingRolesToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :can_publish_events, :boolean, default: false
    add_column :organizations, :can_publish_market, :boolean, default: false
    add_column :organizations, :can_publish_talk, :boolean, default: false
    add_column :organizations, :can_publish_ads, :boolean, default: false
  end
end
