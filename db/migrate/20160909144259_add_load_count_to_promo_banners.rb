class AddLoadCountToPromoBanners < ActiveRecord::Migration
  def up
    change_table :promotion_banners do |t|
      t.integer :load_count, :integer, default: 0
    end

    execute "UPDATE promotion_banners SET load_count=impression_count"
  end

  def down
    remove_column :promotion_banners, :load_count
  end
end
