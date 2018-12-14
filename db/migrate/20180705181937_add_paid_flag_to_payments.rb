class AddPaidFlagToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :paid, :boolean, default: false
  end
end
