class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :content_id
      t.string :event_type
#      t.datetime :start_date
#      t.datetime :end_date
      t.integer :venue_id
      t.string :cost
      t.string :event_url
      t.string :sponsor
      t.string :sponsor_url
      t.text :links
      t.boolean :featured

      t.timestamps
    end
  end
end
