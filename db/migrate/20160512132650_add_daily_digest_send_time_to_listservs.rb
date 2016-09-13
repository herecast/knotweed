class AddDailyDigestSendTimeToListservs < ActiveRecord::Migration
  def change
    add_column :listservs, :daily_digest_send_time, :time
  end
end
