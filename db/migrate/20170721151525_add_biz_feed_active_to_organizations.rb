class AddBizFeedActiveToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :biz_feed_active, :boolean, default: false
    Organization.find_each { |o| o.update_attribute(:biz_feed_active, false) }
  end
end
