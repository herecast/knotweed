class CreateMarketPosts < ActiveRecord::Migration
  def change
    create_table :market_posts do |t|
      t.string :cost
      t.string :contact_phone
      t.string :contact_email
      t.string :contact_url
      t.string :locate_name
      t.string :locate_address
      t.float :latitude
      t.float :longitude
      t.boolean :locate_include_name

      t.timestamps
    end
  end
end
