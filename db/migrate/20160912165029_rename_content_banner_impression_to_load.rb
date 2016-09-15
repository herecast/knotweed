class RenameContentBannerImpressionToLoad < ActiveRecord::Migration
  def up
    create_table :content_promotion_banner_loads do |t|
      t.references :content
      t.references :promotion_banner
      t.integer :load_count, default: 1
      t.string :select_method
      t.float :select_score

      t.timestamps
    end

    execute <<-SQL
      INSERT INTO content_promotion_banner_loads
        (id, content_id, promotion_banner_id, load_count, created_at, updated_at, select_method, select_score)
      SELECT id, content_id, promotion_banner_id, display_count, created_at, updated_at, select_method, select_score
      FROM content_promotion_banner_impressions;

      SELECT setval('content_promotion_banner_loads_id_seq', max(id)) FROM content_promotion_banner_loads;
    SQL

    drop_table :content_promotion_banner_impressions
  end

  def down
    create_table :content_promotion_banner_impressions do |t|
      t.references :content
      t.references :promotion_banner
      t.integer :display_count, default: 1
      t.string :select_method
      t.float :select_score

      t.timestamps
    end

    execute <<-SQL
      INSERT INTO content_promotion_banner_impressions
        (id, content_id, promotion_banner_id, display_count, created_at, updated_at, select_method, select_score)
      SELECT id, content_id, promotion_banner_id, load_count, created_at, updated_at, select_method, select_score
      FROM content_promotion_banner_loads

      SELECT setval('content_promotion_banner_impressions_id_seq', max(id)) FROM content_promotion_banner_impressions;
    SQL

    drop_table :content_promotion_banner_loads
  end
end
