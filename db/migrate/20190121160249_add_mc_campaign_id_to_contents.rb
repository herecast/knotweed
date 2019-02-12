class AddMcCampaignIdToContents < ActiveRecord::Migration[5.1]
  def change
    add_column :contents, :mc_campaign_id, :string
  end
end
