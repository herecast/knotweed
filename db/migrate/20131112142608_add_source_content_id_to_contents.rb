class AddSourceContentIdToContents < ActiveRecord::Migration
  def change
    add_column :contents, :source_content_id, :string
  end
end
