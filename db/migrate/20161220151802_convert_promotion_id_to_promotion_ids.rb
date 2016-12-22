class ConvertPromotionIdToPromotionIds < ActiveRecord::Migration
  def up
    add_column :listservs, :promotion_ids, :integer, array: true, default: []
    execute 'UPDATE listservs SET promotion_ids = ARRAY[promotion_id]';
    remove_column :listservs, :promotion_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
