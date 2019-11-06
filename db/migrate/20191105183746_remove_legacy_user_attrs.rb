class RemoveLegacyUserAttrs < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :agreed_to_nda, :boolean
    remove_column :users, :nda_agreed_at, :datetime
    remove_column :users, :contact_url, :string
    remove_column :users, :test_group, :string
    remove_column :users, :muted, :boolean 
    remove_column :users, :temp_password, :string
  end
end
