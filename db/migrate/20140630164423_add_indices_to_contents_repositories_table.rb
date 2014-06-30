class AddIndicesToContentsRepositoriesTable < ActiveRecord::Migration
  def change
    add_index :contents_repositories, :content_id
    add_index :contents_repositories, :repository_id
  end
end
