class AddAdServiceIdToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :ad_service_id, :string
    add_index :organizations, :ad_service_id
  end
end
