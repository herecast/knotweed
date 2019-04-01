# frozen_string_literal: true

class AddUniqueIndexToOrganizationSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_index :organization_subscriptions, %i[user_id organization_id], unique: true
  end
end
