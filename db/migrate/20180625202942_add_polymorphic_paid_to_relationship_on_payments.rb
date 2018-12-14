# frozen_string_literal: true

class AddPolymorphicPaidToRelationshipOnPayments < ActiveRecord::Migration
  def change
    change_table :payments do |t|
      t.references :paid_to, polymorphic: true, index: true
    end
  end
end
