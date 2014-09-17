class AddIndexToContentsRepositoriesOnRepositoryIdAndContentId < ActiveRecord::Migration
  def change
    add_index :contents_repositories, [:repository_id, :content_id]
  end
end
