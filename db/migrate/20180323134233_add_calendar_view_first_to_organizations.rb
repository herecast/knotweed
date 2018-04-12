class AddCalendarViewFirstToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :calendar_view_first, :boolean, default: false
  end
end
