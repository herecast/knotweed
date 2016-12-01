class CreateMarketCategories < ActiveRecord::Migration
  def change
    create_table :market_categories do |t|
      t.string :name
      t.string :query
      t.string :category_image
      t.string :detail_page_banner
      t.boolean :featured, default: false
      t.boolean :trending, default: false
      t.integer :result_count

      t.timestamps null: false
    end
  end
end
