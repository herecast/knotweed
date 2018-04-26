class RemoveProfileTitleFromOrganizations < ActiveRecord::Migration
  def change
    remove_column :organizations, :profile_title, :string
  end
end
