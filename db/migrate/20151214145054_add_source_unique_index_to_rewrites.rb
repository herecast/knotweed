class AddSourceUniqueIndexToRewrites < ActiveRecord::Migration
  def change
    add_index :rewrites, :source, unique: true
  end
end
