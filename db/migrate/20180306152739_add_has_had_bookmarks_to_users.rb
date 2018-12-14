class AddHasHadBookmarksToUsers < ActiveRecord::Migration
  def change
    add_column :users, :has_had_bookmarks, :boolean, default: false
  end
end
