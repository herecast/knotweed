class RemovePublishedFlagFromContents < ActiveRecord::Migration
  def change
    remove_column :contents, :published, :boolean, index: true
  end
end
