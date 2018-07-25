# == Schema Information
#
# Table name: payments
#
#  id              :integer          not null, primary key
#  period_start    :date
#  period_end      :date
#  paid_impressions      :integer
#  pay_per_impression    :decimal(, )
#  total_payment   :decimal(, )
#  payment_date    :datetime
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_payments_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_3ab959bfc4  (organization_id => organizations.id)
#

class Payment < ActiveRecord::Base
  belongs_to :content
  belongs_to :paid_to, class_name: 'User', foreign_key: 'paid_to'

  validates :content_id, uniqueness: { scope: [:period_start, :period_end] }

  scope :for_user, ->(user_id) { where('paid_to = ?', user_id) }

  # pay_per_impression can't be used in the group_by clause because its being a float
  # makes it potentially not always exactly the same (I think). That said, it is
  # always very very close to the same, so we are just taking MIN here.
  scope :by_period, -> {
    select('period_start, period_end, MIN(pay_per_impression) as pay_per_impression, MIN(payment_date) as payment_date, SUM(paid_impressions) as paid_impressions, SUM(total_payment) as total_payment').
    group(:period_start, :period_end).
    order('payment_date DESC')
  }

  scope :unpaid, -> { where(paid: false) }
  scope :paid, -> { where(paid: true) }

end
