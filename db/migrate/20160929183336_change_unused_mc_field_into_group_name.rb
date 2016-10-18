class ChangeUnusedMcFieldIntoGroupName < ActiveRecord::Migration
  def change
    rename_column :listservs, :mc_segment_id, :mc_group_name
  end
end
