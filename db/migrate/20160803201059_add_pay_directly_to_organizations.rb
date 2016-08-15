class AddPayDirectlyToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :pay_directly, :boolean, default: false
  end
end
