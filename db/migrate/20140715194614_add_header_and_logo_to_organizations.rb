class AddHeaderAndLogoToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :header, :string
    add_column :organizations, :logo, :string
  end
end
