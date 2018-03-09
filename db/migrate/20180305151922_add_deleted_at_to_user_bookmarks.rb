class AddDeletedAtToUserBookmarks < ActiveRecord::Migration
  def change
    add_column :user_bookmarks, :deleted_at, :datetime
    add_index :user_bookmarks, :deleted_at
  end
end
