class AddIndicesForNewEventsModel < ActiveRecord::Migration
  def change
    add_index :events, :content_id
    add_index :events, :venue_id
    add_index :events, :featured
    add_index :event_instances, :event_id
    add_index :event_instances, :start_date
    add_index :event_instances, :end_date
  end
end
