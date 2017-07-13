class AddTwitterHandleToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :twitter_handle, :string
  end
end
