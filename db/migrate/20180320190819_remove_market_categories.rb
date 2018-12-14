class RemoveMarketCategories < ActiveRecord::Migration
  def up
    drop_table :market_categories
  end

  def down
    create_table :market_categories do |t|
      t.string :name
      t.string :query
      t.string :category_image
      t.string :detail_page_banner
      t.boolean :featured, default: false
      t.boolean :trending, default: false
      t.integer :result_count
      t.string :query_modifier, default: 'AND'

      t.timestamps null: false
    end
  end
end
