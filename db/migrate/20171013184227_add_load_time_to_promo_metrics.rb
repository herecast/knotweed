class AddLoadTimeToPromoMetrics < ActiveRecord::Migration
  def change
    change_table :promotion_banner_metrics do |t|
      t.float :load_time
    end
  end
end
