class RemoveBlogContactNameFromOrganizations < ActiveRecord::Migration
  def change
    remove_column :organizations, :blog_contact_name, :string
  end
end
