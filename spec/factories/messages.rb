# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  # default message factory is active
  factory :message do
    association :created_by, factory: :user
    controller Message::CONTROLLER_OPTIONS[0]
    start_date 1.day.ago
    content "MyText"

    trait :inactive do
      end_date 1.hour.ago
    end
  end
end
