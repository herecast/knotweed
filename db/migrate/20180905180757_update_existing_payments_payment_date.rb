class UpdateExistingPaymentsPaymentDate < ActiveRecord::Migration
  def up
    change_column :payments, :payment_date, :date
    period_ends = Payment.select("DISTINCT(period_end)").map{ |p| p.period_end }
    period_ends.each do |p_end|
      payment_date = p_end.next_month.beginning_of_month + 9.days
      Payment.where(period_end: p_end).update_all(payment_date: payment_date)
    end
  end

  def down
    change_column :payments, :payment_date, :datetime
  end
end
