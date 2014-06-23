class AddIndexOnParentIdForContents < ActiveRecord::Migration
  def change
    add_index :contents, :parent_id
  end
end
