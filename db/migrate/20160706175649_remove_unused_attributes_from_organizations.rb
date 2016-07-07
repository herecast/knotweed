class RemoveUnusedAttributesFromOrganizations < ActiveRecord::Migration
  def up
    remove_column :organizations, :category_override
    remove_column :organizations, :reverse_publish_email
    remove_column :organizations, :display_attributes
  end

  def down
    add_column :organizations, :category_override
    add_column :organizations, :reverse_publish_email
    add_column :organizations, :display_attributes
  end
end
