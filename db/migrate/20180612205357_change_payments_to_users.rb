class ChangePaymentsToUsers < ActiveRecord::Migration
  def change
    remove_column :payments, :organization_id, :integer
    add_reference :payments, :user, foreign_key: true
  end
end
