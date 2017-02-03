class AddQueryOptionsToMarketCategories < ActiveRecord::Migration
  def change
    add_column :market_categories, :query_modifier, :string, default:'AND'
  end
end
