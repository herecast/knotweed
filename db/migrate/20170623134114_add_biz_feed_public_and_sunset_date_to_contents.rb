class AddBizFeedPublicAndSunsetDateToContents < ActiveRecord::Migration
  def change
    add_column :contents, :biz_feed_public, :boolean
    add_column :contents, :sunset_date, :datetime
  end
end
