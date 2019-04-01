# frozen_string_literal: true

class AddFlagTypeToOrganizationHides < ActiveRecord::Migration[5.1]
  def change
    add_column :organization_hides, :flag_type, :string
  end
end
