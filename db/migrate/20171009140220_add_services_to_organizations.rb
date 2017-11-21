class AddServicesToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :services, :string
  end
end
