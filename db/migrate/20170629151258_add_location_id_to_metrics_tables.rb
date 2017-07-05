class AddLocationIdToMetricsTables < ActiveRecord::Migration
  def change
    add_column :content_metrics, :location_id, :integer, null: true
    add_column :promotion_banner_metrics, :location_id, :integer, null: true
  end
end
