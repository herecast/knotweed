class AddDigestTrackingToListservs < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.boolean :send_digest, default: false
      t.datetime :last_digest_send_time
      t.datetime :last_digest_generation_time
    end
  end
end
