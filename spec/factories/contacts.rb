# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    name "MyString"
    phone "MyString"
    email "MyString"
    notes "MyText"
  end
end
