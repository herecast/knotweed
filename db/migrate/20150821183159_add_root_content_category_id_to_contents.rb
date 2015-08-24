class AddRootContentCategoryIdToContents < ActiveRecord::Migration
  def up
    add_column :contents, :root_content_category_id, :integer

    # set it retroactively
    execute <<-SQL
      UPDATE contents 
        SET root_content_category_id = (SELECT IF(parent_id IS NOT NULL, parent_id, id) 
        from content_categories where content_categories.id=contents.content_category_id)
    SQL
  end

  def down
    remove_column :contents, :root_content_category_id
  end
end
