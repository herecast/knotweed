class AddEventFieldsToContent < ActiveRecord::Migration
  def change
    add_column :contents, :event_type, :string
    add_column :contents, :start_date, :datetime
    add_column :contents, :end_date, :datetime
    add_column :contents, :cost, :string
    add_column :contents, :recurrence, :string
    add_column :contents, :links, :text
    add_column :contents, :host_organization, :string
  end
end
