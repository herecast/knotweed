class AddBannerClickCountToContents < ActiveRecord::Migration
  def change
    add_column :contents, :banner_click_count, :integer, default: 0
  end
end
