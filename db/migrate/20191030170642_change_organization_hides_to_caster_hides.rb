class ChangeOrganizationHidesToCasterHides < ActiveRecord::Migration[5.1]
  def change
    rename_table :organization_hides, :caster_hides
  end
end
