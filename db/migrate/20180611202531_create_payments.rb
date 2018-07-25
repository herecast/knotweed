class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.date :period_start
      t.date :period_end
      t.integer :paid_reads
      t.decimal :pay_per_read
      t.decimal :total_payment
      t.datetime :payment_date
      t.references :organization, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
