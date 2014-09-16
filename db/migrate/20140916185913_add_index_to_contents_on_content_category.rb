class AddIndexToContentsOnContentCategory < ActiveRecord::Migration
  def change
    add_index :contents, :content_category_id, name: 'content_category_id'
  end
end
