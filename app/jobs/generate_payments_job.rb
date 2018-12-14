class GeneratePaymentsJob < ApplicationJob
  def perform(period_start, period_end, period_ad_rev)
    GeneratePayments.call(period_start: period_start, period_end: period_end, period_ad_rev: period_ad_rev)
  end
end
