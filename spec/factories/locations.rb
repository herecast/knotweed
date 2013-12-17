# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :location do
    zip "MyString"
    city "MyString"
    state "MyString"
    county "MyString"
    lat "MyString"
    long "MyString"
  end
end
