class AddMcSegmentIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mc_segment_id, :string
  end
end
