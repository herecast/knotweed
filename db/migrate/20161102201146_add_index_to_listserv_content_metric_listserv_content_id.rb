class AddIndexToListservContentMetricListservContentId < ActiveRecord::Migration
  def change
    add_index :listserv_content_metrics, :listserv_content_id
  end
end
