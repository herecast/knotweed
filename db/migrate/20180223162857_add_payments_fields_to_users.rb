class AddPaymentsFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :fullname, :string
    add_column :users, :nickname, :string
    add_column :users, :epayment, :boolean, default: false
    add_column :users, :w9, :boolean, default: false
  end
end
