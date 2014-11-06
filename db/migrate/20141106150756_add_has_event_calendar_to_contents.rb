class AddHasEventCalendarToContents < ActiveRecord::Migration
  def change
    add_column :contents, :has_event_calendar, :boolean, default: false
  end
end
