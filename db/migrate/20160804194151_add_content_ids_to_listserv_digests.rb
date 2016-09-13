class AddContentIdsToListservDigests < ActiveRecord::Migration
  def change
    change_table :listserv_digests do |t|
      t.string :content_ids
    end
  end
end
