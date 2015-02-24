class RemoveUnusedFieldsFromContent < ActiveRecord::Migration
  def up
    remove_column :contents, :wordcount
    remove_column :contents, :file
    remove_column :contents, :mimetype
    remove_column :contents, :page
    remove_column :contents, :doctype
  end

  def down
    add_column :contents, :wordcount, :string
    add_column :contents, :file, :string
    add_column :contents, :mimetype, :string
    add_column :contents, :page, :string
    add_column :contents, :doctype, :string
  end
end
