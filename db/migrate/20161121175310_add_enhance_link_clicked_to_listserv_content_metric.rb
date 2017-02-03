class AddEnhanceLinkClickedToListservContentMetric < ActiveRecord::Migration
  def change
    add_column :listserv_content_metrics, :enhance_link_clicked, :boolean, default: false
  end
end
