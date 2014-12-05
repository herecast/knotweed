class AddDefaultRepositoryToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_repository_id, :integer
  end
end
