class AddSpecialLinksToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :special_link_url, :string
    add_column :organizations, :special_link_text, :string
  end
end
