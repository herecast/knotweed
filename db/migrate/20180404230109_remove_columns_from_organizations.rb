# frozen_string_literal: true

class RemoveColumnsFromOrganizations < ActiveRecord::Migration
  def change
    remove_column :organizations, :can_publish_events, :boolean, default: false
    remove_column :organizations, :can_publish_market, :boolean, default: false
    remove_column :organizations, :can_publish_talk, :boolean, default: false
    remove_column :organizations, :can_publish_ads, :boolean, default: false
    remove_column :organizations, :profile_ad_override, :string
  end
end
