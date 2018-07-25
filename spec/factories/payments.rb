# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :payment do
    period_start Date.parse("2018-06-11")
    period_end Date.parse("2018-06-20")
    paid_impressions 1
    pay_per_impression 9.99
    total_payment 9.99
    payment_date Time.current
    content
    association :paid_to, factory: :user 
  end
end
