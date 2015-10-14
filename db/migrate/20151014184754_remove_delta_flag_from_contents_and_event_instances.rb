class RemoveDeltaFlagFromContentsAndEventInstances < ActiveRecord::Migration
  def up
    remove_column :event_instances, :delta
    remove_column :contents, :delta
  end

  def down
    add_column :event_instances, :delta, :boolean, default: false
    add_column :contents, :delta, :boolean, default: false
  end
end
