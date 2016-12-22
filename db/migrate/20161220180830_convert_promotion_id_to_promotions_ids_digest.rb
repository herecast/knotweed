class ConvertPromotionIdToPromotionsIdsDigest < ActiveRecord::Migration
  def up
    add_column :listserv_digests, :promotion_ids, :integer, array: true, default: []
    execute 'UPDATE listserv_digests SET promotion_ids = ARRAY[promotion_id]';
    remove_column :listserv_digests, :promotion_id
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
