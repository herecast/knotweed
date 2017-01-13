class AddSoldToMarketPosts < ActiveRecord::Migration
  def change
    add_column :market_posts, :sold, :boolean, default: false
  end
end
