# frozen_string_literal: true

class CreatePaymentRecipients < ActiveRecord::Migration
  def change
    create_table :payment_recipients do |t|
      t.references :user, index: true, foreign_key: true
      t.string :alternative_emails
      t.references :organization, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
