class AddMcListIdToListservs < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.string :mc_list_id
      t.string :mc_segment_id
    end
  end
end
