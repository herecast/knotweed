# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    content
    start_date 1.week.from_now
    featured false
    association :venue, factory: :business_location
  end
end
