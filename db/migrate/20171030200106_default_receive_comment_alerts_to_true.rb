class DefaultReceiveCommentAlertsToTrue < ActiveRecord::Migration
  def up
    change_column_default :users, :receive_comment_alerts, true
    User.update_all(receive_comment_alerts: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
