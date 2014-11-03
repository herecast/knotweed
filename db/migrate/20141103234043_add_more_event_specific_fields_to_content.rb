class AddMoreEventSpecificFieldsToContent < ActiveRecord::Migration
  def change
    add_column :contents, :event_url, :string
    add_column :contents, :sponsor_url, :string
  end
end
