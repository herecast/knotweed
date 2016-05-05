class AddSubscribeUrlToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :subscribe_url, :string
  end
end
