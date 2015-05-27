class AddDeltaToEventInstances < ActiveRecord::Migration
  def change
    add_column :event_instances, :delta, :boolean, default: true, null: false
  end
end
