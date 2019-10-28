class AddEmailIsPublicToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :email_is_public, :boolean, default: false
  end
end
