class AddRootParentIdToContents < ActiveRecord::Migration
  def change
    # NOTE: there's a rake task called backpopulate:root_parent_ids
    #
    #   rake backpopulate:root_parent_ids
    #
    add_column :contents, :root_parent_id, :integer
    add_index :contents, :root_parent_id
  end
end
