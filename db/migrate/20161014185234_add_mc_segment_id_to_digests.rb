class AddMcSegmentIdToDigests < ActiveRecord::Migration
  def change
    add_column :listserv_digests, :mc_segment_id, :string
  end
end
