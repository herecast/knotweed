# frozen_string_literal: true

class AddReadToUserBookmarks < ActiveRecord::Migration
  def change
    add_column :user_bookmarks, :read, :boolean, default: false
  end
end
