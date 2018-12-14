# frozen_string_literal: true

class RemoveOrganizationIdFromPromotions < ActiveRecord::Migration
  def change
    remove_column :promotions, :organization_id, :integer
  end
end
