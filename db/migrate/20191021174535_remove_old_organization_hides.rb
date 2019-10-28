class RemoveOldOrganizationHides < ActiveRecord::Migration[5.1]
  def up
    OrganizationHide.destroy_all
    remove_column :organization_hides, :organization_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
