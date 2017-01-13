class ConvertPromotionIdToPromotionsIdsCampaign < ActiveRecord::Migration
  def up
    add_column :campaigns, :promotion_ids, :integer, array: true, default: []
    execute 'UPDATE campaigns SET promotion_ids = ARRAY[promotion_id]';
    remove_column :campaigns, :promotion_id
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
