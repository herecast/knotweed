class AddSharePlatformToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :share_platform, :string
  end
end
