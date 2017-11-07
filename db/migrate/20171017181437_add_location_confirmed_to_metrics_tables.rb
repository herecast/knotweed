class AddLocationConfirmedToMetricsTables < ActiveRecord::Migration
  def change
    change_table :promotion_banner_metrics do |t|
      t.boolean :location_confirmed, default: false
    end

    change_table :content_metrics do |t|
      t.boolean :location_confirmed, default: false
    end
  end
end
