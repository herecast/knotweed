class AddClientIdToMetrics < ActiveRecord::Migration
  def change
    add_column :promotion_banner_metrics, :client_id, :string
    add_column :content_metrics, :client_id, :string
  end
end
