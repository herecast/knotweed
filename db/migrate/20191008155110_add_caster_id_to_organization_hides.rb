class AddCasterIdToOrganizationHides < ActiveRecord::Migration[5.1]
  def change
    add_column :organization_hides, :caster_id, :integer
    add_index :organization_hides, :caster_id
  end
end
