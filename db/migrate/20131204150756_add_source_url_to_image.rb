class AddSourceUrlToImage < ActiveRecord::Migration
  def change
    add_column :images, :source_url, :string, limit: 400
  end
end
