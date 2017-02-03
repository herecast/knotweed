class CreateAdMetrics < ActiveRecord::Migration
  def change
    create_table :ad_metrics do |t|
      t.string :campaign
      t.string :event_type
      t.string :page_url
      t.string :content

      t.timestamps null: false
    end
  end
end
