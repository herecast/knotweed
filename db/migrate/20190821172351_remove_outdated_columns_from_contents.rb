class RemoveOutdatedColumnsFromContents < ActiveRecord::Migration[5.1]
  def change
    remove_column :contents, :guid, :string
    remove_column :contents, :quarantine, :boolean
  end
end
