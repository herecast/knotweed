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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment do
    period_start Date.parse('2018-06-11')
    period_end Date.parse('2018-06-20')
    paid_impressions 1
    pay_per_impression 9.99
    total_payment 9.99
    payment_date Time.current
    period_ad_rev 100.50
    content
    association :paid_to, factory: :user
  end
end
