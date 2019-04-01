# frozen_string_literal: true

class SendPaymentsJob < ApplicationJob
  def perform(period_start, period_end)
    # we are querying payments by user so we can sum the amount and issue the payment with one invoice.
    # However, we need to update `paid` to true on all individual payment records, so we need to track
    # which users it succeeds for and then update based on that
    successfully_paid_users = []
    Payment.unpaid.by_user.where(period_start: Date.parse(period_start), period_end: Date.parse(period_end)).each do |payment|
      logger.debug "calling send_payment for: #{payment.id} #{payment.total_payment}"
      invoice_date = Date.parse(period_end).next_month.beginning_of_month
      BillDotComService.send_payment(
        vendor_name: payment.fullname,
        amount: payment.total_payment.to_f.round(2),
        invoice_number: payment.id,
        invoice_date: invoice_date
      )
      successfully_paid_users << payment.paid_to_user_id
    rescue BillDotComExceptions::UnexpectedResponse => e
      logger.error "Payment #{payment.id} failed: #{e}"
    end
    Payment.where(paid_to: successfully_paid_users, period_start: Date.parse(period_start),
                  period_end: Date.parse(period_end)).update_all(paid: true)
  end
end
