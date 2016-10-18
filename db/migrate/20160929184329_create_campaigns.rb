class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.references :listserv, index: true, foreign_key: true
      t.integer :community_ids, array: true, default: [], index: true
      t.references :promotion, index: true, foreign_key: true
      t.string :sponsored_by
      t.text :digest_query

      t.timestamps null: false
    end
  end
end
