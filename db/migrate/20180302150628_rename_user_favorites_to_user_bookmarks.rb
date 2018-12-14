# frozen_string_literal: true

class RenameUserFavoritesToUserBookmarks < ActiveRecord::Migration
  def change
    rename_table :user_favorites, :user_bookmarks
  end
end
