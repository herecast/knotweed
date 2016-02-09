# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_feedback do
    created_by
    business_profile
  end
end
