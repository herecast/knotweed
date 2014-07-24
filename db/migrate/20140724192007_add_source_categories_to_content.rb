class AddSourceCategoriesToContent < ActiveRecord::Migration
  def change
    rename_column :contents, :categories, :source_category
    add_column :contents, :category, :string
  end
end
