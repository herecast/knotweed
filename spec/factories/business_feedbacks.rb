# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_feedback do
    business_profile
    satisfaction true
    cleanliness true
    price true
    recommend true
  end
end
