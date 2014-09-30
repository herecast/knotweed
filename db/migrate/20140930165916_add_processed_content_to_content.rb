class AddProcessedContentToContent < ActiveRecord::Migration
  def change
    add_column :contents, :processed_content, :text
    rename_column :contents, :content, :raw_content
  end
end
