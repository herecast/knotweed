class AddMetricsToContent < ActiveRecord::Migration
  def change
    add_column :contents, :view_count, :integer, default: 0
    add_column :contents, :comment_count, :integer, default: 0
    add_column :contents, :commenter_count, :integer, default: 0
  end
end
