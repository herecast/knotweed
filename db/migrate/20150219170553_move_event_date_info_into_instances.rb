class MoveEventDateInfoIntoInstances < ActiveRecord::Migration
  
  # This migration takes all existing event records and migrates the start_date/end_date
  # to the new event_instance model that supports multiple date-times for single master
  # events and drops the unnecessary fields from the event model after it's done
  def up
    Event.all.each do |e|
      instance = EventInstance.create(event_id: e.id, start_date: e.start_date, end_date: e.end_date)
    end
    remove_column :events, :start_date
    remove_column :events, :end_date
  end

  # Restores the start_date and end_date columns to the event model and assigns them values
  # using the first event_instance attached to the event record.
  def down
    add_column :events, :start_date, :datetime
    add_column :events, :end_date, :datetime
    # we don't really have a way of reverting this from the scenario where events have multiple
    # instances...so we're just picking the first one
    Event.all.each do |e|
      if e.event_instances.present?
        e.start_date = e.event_instances.first.start_date
        e.end_date = e.event_instances.first.end_date
        e.save
      end
    end
  end

end
