class RenameTypeColumnOnAnnotations < ActiveRecord::Migration
  def change
    rename_column :annotations, :type, :annotation_type
  end
end
