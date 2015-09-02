class AddFieldsToMarketPosts < ActiveRecord::Migration
  def change
    add_column :market_posts, :status, :string
    add_column :market_posts, :preferred_contact_method, :string
  end
end
