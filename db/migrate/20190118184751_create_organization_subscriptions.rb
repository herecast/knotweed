# frozen_string_literal: true

class CreateOrganizationSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :organization_subscriptions do |t|
      t.references :user, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :mc_subscriber_id

      t.timestamps
    end
  end
end
