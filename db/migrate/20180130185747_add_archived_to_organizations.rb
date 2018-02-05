class AddArchivedToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :archived, :boolean, default: false
  end
end
