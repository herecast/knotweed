# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_location do
    name "MyString"
    organization_id 1
    address "MyString"
    phone "MyString"
    email "MyString"
    hours "MyString"
  end
end
