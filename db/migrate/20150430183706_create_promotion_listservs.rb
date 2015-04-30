class CreatePromotionListservs < ActiveRecord::Migration
  def change
    create_table :promotion_listservs do |t|
      t.integer :listserv_id
      t.datetime :sent_at

      t.timestamps
    end
  end
end
