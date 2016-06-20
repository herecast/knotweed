class AddBannerAdOverrideToOrganization < ActiveRecord::Migration
  def change
    change_table :organizations do |t|
      t.string :banner_ad_override
    end
  end
end
