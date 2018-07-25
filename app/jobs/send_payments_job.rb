class SendPaymentsJob < ApplicationJob

  def perform(period_start, period_end)
    Payment.unpaid.where(period_start: Date.parse(period_start), period_end: Date.parse(period_end)).each do |payment|
      payment.mark_paid!
    end
  end

end
