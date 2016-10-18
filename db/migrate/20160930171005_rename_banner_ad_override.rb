class RenameBannerAdOverride < ActiveRecord::Migration
  def change
    rename_column :listservs, :banner_ad_override_id, :promotion_id
  end
end
