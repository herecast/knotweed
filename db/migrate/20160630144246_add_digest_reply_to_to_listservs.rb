class AddDigestReplyToToListservs < ActiveRecord::Migration
  def change
    change_table :listservs do |t|
      t.string :digest_reply_to
    end
  end
end
