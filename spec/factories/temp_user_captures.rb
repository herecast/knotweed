# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :temp_user_capture do
    name Faker::Name.name
    sequence(:email) { |i| "temp_user_#{i}@test.com" }
  end
end
