# frozen_string_literal: true

class AddReminderCampaignIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :reminder_campaign_id, :string
  end
end
