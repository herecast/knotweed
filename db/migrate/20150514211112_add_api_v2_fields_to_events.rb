class AddApiV2FieldsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :cost_type, :string
    add_column :events, :event_category, :string
  end
end
