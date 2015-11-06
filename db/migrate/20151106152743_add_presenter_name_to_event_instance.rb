class AddPresenterNameToEventInstance < ActiveRecord::Migration
  def change
    add_column :event_instances, :presenter_name, :string
  end
end
