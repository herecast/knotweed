class CreateEventInstances < ActiveRecord::Migration
  def change
    create_table :event_instances do |t|
      t.integer :event_id
      t.datetime :start_date
      t.datetime :end_date
      t.string :subtitle_override
      t.text :description_override

      t.timestamps
    end
  end
end
