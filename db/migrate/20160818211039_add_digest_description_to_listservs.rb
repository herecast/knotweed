class AddDigestDescriptionToListservs < ActiveRecord::Migration
  def change
    add_column :listservs, :digest_description, :text
    add_column :listservs, :digest_send_day, :string
    rename_column :listservs, :daily_digest_send_time, :digest_send_time
  end
end
