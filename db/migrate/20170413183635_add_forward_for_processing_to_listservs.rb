class AddForwardForProcessingToListservs < ActiveRecord::Migration
  def change
    add_column :listservs, :forward_for_processing, :boolean, default: false
  end
end
