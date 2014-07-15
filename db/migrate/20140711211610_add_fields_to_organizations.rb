class AddFieldsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :tagline, :string
    add_column :organizations, :links, :text
    add_column :organizations, :social_media, :text
    add_column :organizations, :general, :text
  end
end
