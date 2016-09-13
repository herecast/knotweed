class CreateListservDigests < ActiveRecord::Migration
  def change
    create_table :listserv_digests do |t|
      t.references :listserv, index: true, foreign_key: true
      t.string :listserv_content_ids
      t.string :campaign_id
      t.datetime :sent_at

      t.timestamps null: false
    end
  end
end
