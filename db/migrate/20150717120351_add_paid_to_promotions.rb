class AddPaidToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :paid, :boolean, default: false
  end
end
