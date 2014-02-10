class AddImportUrlPathToContentSets < ActiveRecord::Migration
  def change
    add_column :content_sets, :import_url_path, :string
  end
end
