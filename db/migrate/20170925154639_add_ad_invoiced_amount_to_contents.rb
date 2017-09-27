class AddAdInvoicedAmountToContents < ActiveRecord::Migration
  def change
    add_column :contents, :ad_invoiced_amount, :float
  end
end
