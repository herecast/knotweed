class AddAdPromoterToContents < ActiveRecord::Migration
  def change
    add_column :contents, :ad_promoter, :integer
  end
end
