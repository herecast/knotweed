class AllowLongerStringsInEventsEventUrl < ActiveRecord::Migration
  def up
    change_column :events, :event_url, :string
  end

  def down
    change_column :events, :event_url, :string, limit: 255
  end
end
