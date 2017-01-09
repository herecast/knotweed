class CreateContentMetrics < ActiveRecord::Migration
  def change
    create_table :content_metrics do |t|
      t.integer :content_id
      t.string :event_type
      t.integer :user_id
      t.string :user_agent
      t.string :user_ip

      t.timestamps null: false
    end
  end
end
