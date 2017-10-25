class AddReceiveCommentAlertToUsers < ActiveRecord::Migration
  def change
    add_column :users, :receive_comment_alerts, :boolean, default: false
  end
end
