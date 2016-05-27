# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_category do
    sequence(:name) { |n| "Biz Cat #{n}" }
    description "MyString"
    icon_class "MyString"
  end
end
