class AddStepReachedToListservContentMetric < ActiveRecord::Migration
  def change
    add_column :listserv_content_metrics, :step_reached, :string
  end
end
