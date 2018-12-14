class ChangePaidReadsToPaidImpressionsOnPayments < ActiveRecord::Migration
  def change
    rename_column :payments, :paid_reads, :paid_impressions
    rename_column :payments, :pay_per_read, :pay_per_impression
  end
end
