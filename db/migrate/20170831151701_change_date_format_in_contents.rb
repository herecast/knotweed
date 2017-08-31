class ChangeDateFormatInContents < ActiveRecord::Migration
  def up
    change_column :contents, :ad_campaign_start, :date
    change_column :contents, :ad_campaign_end, :date
  end

  def down
    change_column :contents, :ad_campaign_start, :datetime
    change_column :contents, :ad_campaign_end, :datetime
  end
end
