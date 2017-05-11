# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sign_in_token do
    user
    created_at { Time.current }
  end
end
