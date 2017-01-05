class RemoveActiveFromPromotions < ActiveRecord::Migration
  def change
    remove_column :promotions, :active, :boolean
  end
end
