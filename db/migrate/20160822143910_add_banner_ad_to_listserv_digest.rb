class AddBannerAdToListservDigest < ActiveRecord::Migration
  def change
    add_column :listservs, :banner_ad_override_id, :integer
  end
end
