class AddTargetUrlToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :target_url, :string
  end
end
