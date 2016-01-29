class RemoveOrganizationIdFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :organization_id
  end

  def down
    add_column :users, :organization_id, :integer
  end
end
