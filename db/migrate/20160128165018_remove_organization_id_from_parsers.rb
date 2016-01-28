class RemoveOrganizationIdFromParsers < ActiveRecord::Migration
  def up
    remove_column :parsers, :organization_id
  end

  def down
    add_column :parsers, :organization_id, :integer
  end
end
