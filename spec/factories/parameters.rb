# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :parameter do
    parser
    sequence(:name) { |n| "Param-#{n}" }
  end
end
