class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.text :recurrence
      t.integer :event_id
      t.text :description_override
      t.string :subtitle_override
      t.string :presenter_name 

      t.timestamps
    end
    add_column :event_instances, :schedule_id, :integer
  end
end
