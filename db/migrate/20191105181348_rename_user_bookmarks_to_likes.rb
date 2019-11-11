class RenameUserBookmarksToLikes < ActiveRecord::Migration[5.1]
  def change
    remove_column :user_bookmarks, :read, :boolean, default: false
    rename_table :user_bookmarks, :likes
    rename_column :users, :has_had_bookmarks, :has_had_likes
  end
end
