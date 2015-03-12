# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :market_post do
    cost "MyString"
    contact_phone "MyString"
    contact_email "MyString"
    contact_url "MyString"
    locate_name "MyString"
    locate_address "MyString"
    latitude 1.5
    longitude 1.5
    locate_include_name false
  end
end
