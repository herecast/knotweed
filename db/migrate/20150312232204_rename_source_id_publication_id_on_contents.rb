class RenameSourceIdPublicationIdOnContents < ActiveRecord::Migration
  def change
    rename_column :contents, :source_id, :publication_id
  end
end
