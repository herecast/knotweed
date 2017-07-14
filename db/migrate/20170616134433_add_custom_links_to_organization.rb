class AddCustomLinksToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :custom_links, :jsonb
  end
end
