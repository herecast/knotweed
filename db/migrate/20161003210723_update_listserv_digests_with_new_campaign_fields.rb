class UpdateListservDigestsWithNewCampaignFields < ActiveRecord::Migration
  def change
    rename_column :listserv_digests, :campaign_id, :mc_campaign_id
    change_table :listserv_digests do |t|
      t.string :sponsored_by
      t.references :promotion
      t.integer :location_ids, array: true, default: []
    end
  end
end
