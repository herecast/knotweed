class AddPostThresholdToListserv < ActiveRecord::Migration
  def change
    add_column :listservs, :post_threshold, :integer, default: 0
  end
end
