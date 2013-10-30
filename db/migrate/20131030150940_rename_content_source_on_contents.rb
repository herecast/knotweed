class RenameContentSourceOnContents < ActiveRecord::Migration
  def change
    rename_column :contents, :contentsource_id, :source_id
    add_column :contents, :contentsource, :string
  end
end
