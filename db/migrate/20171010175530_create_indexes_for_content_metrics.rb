class CreateIndexesForContentMetrics < ActiveRecord::Migration
  def change
    change_table :content_metrics do |t|
      t.index :content_id
      t.index :location_id
      t.index :event_type
      t.index :client_id
      t.index :user_id
    end
  end

end
