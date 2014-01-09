# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    name "MyString"
    phone "MyString"
    email "MyString"
    notes "MyText"
    contact_type Contact::CONTACT_TYPES[0]
  end
end
