class AddAdFieldsToContents < ActiveRecord::Migration
  def change
    add_column :contents, :ad_invoice_paid, :boolean, default: false
    add_column :contents, :ad_commission_amount, :float
    add_column :contents, :ad_commission_paid, :boolean, default: false
    add_column :contents, :ad_services_amount, :float
    add_column :contents, :ad_services_paid, :boolean, default: false
    add_column :contents, :ad_sales_agent, :integer
  end
end
