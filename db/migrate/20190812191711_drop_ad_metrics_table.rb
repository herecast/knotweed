class DropAdMetricsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :ad_metrics
  end
end
