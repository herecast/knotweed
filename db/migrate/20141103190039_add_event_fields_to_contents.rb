class AddEventFieldsToContents < ActiveRecord::Migration
  def change
    add_column :contents, :event_title, :string
    add_column :contents, :event_description, :text
  end
end
