class RemoveAdminFromUsers < ActiveRecord::Migration
  def change
    #remove_column :users, :admin
    execute 'ALTER TABLE users DROP COLUMN IF EXISTS admin'
  end
end
