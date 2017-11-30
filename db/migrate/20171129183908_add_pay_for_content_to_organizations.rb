class AddPayForContentToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :pay_for_content, :boolean, default: false
  end
end
