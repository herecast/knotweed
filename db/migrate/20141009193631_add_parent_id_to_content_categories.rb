class AddParentIdToContentCategories < ActiveRecord::Migration
  def change
    add_column :content_categories, :parent_id, :integer
  end
end
