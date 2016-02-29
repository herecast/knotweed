class AddIndexToCategoryCorrections < ActiveRecord::Migration
  def change
    add_index :category_corrections, :content_id
  end
end
