class CreateProfileMetrics < ActiveRecord::Migration
  def change
    create_table :profile_metrics do |t|
      t.references :organization, index: true, foreign_key: true
      t.references :location, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.references :content, index: true, foreign_key: true
      t.string :event_type, index: true
      t.string :user_ip
      t.string :user_agent
      t.string :client_id, index: true
      t.boolean :location_confirmed

      t.timestamps null: false
    end
  end
end
