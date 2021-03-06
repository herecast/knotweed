# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                 :bigint(8)        not null, primary key
#  period_start       :date
#  period_end         :date
#  paid_impressions   :integer
#  pay_per_impression :decimal(, )
#  total_payment      :decimal(, )
#  payment_date       :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  content_id         :integer
#  paid_to_id         :integer
#  period_ad_rev      :decimal(, )
#  paid               :boolean          default(FALSE)
#
# Indexes
#
#  index_payments_on_paid_to_id  (paid_to_id)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#

class Payment < ActiveRecord::Base
  belongs_to :content
  belongs_to :paid_to, class_name: 'User', foreign_key: 'paid_to_id'

  validates :content_id, uniqueness: { scope: %i[period_start period_end] }

  scope :for_user, ->(user_id) { where('paid_to_id = ?', user_id) }

  # pay_per_impression can't be used in the group_by clause because its being a float
  # makes it potentially not always exactly the same (I think). That said, it is
  # always very very close to the same, so we are just taking MIN here.
  scope :by_period, lambda {
    select('MIN(payments.id) as id, MIN(fullname) as fullname, period_start, period_end, MIN(pay_per_impression) as pay_per_impression, MIN(payment_date) as payment_date, SUM(paid_impressions) as paid_impressions, SUM(total_payment) as total_payment, MIN(period_ad_rev) as period_ad_rev')
      .joins(:paid_to)
      .group(:period_start, :period_end)
      .order('payment_date DESC')
  }

  scope :by_user, lambda {
    select('MIN(payments.id) as id, users.id as paid_to_user_id, fullname, period_start, period_end, SUM(total_payment) as total_payment')
      .joins(:paid_to)
      .group(:period_start, :period_end, :fullname, :paid_to_user_id)
      .order('fullname ASC')
  }

  scope :unpaid, -> { where(paid: false) }
  scope :paid, -> { where(paid: true) }

  # this is a bit cheeky in that it can be used on regular scopes
  # OR on the `by_period` grouping scope which just takes the first ID
  # as "id" and selects `paid_to.fullname` directly onto the `fullname`
  # attribute
  def self.to_csv
    headers = ['Vendor Name', 'Invoice #', 'Invoice Date', 'Due Date', 'Amount', 'Account']

    CSV.generate(headers: true) do |csv|
      csv << headers

      all.each do |payment|
        attrs = []
        attrs << (payment.try(:fullname) || payment.paid_to.try(:fullname))
        attrs << payment.id
        attrs << payment.invoice_date
        attrs << payment.invoice_date + 9.days
        attrs << payment.total_payment
        attrs << BillDotComService::CHART_OF_ACCOUNT_ID
        csv << attrs
      end
    end
  end

  def invoice_date
    period_end.next_month.beginning_of_month
  end

  def revenue_share
    (total_payment * 100 / period_ad_rev).truncate(2) if period_ad_rev.present?
  end

  def mark_paid!
    update paid: true
  end
end
