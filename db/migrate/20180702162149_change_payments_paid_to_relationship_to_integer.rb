# frozen_string_literal: true

class ChangePaymentsPaidToRelationshipToInteger < ActiveRecord::Migration
  def change
    remove_column :payments, :paid_to_type, :string
    remove_column :payments, :paid_to_id, :integer
    add_column :payments, :paid_to, :integer
    add_index :payments, :paid_to
  end
end
