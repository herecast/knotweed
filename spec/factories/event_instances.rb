# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_instance do
    event
    start_date 1.week.from_now
  end
end
