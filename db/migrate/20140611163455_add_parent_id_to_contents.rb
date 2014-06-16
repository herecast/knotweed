class AddParentIdToContents < ActiveRecord::Migration
  def change
    add_column :contents, :parent_id, :integer
  end
end
