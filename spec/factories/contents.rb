# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title "MyString"
    subtitle "MyString"
    authors "MyString"
    subject "MyString"
    content "MyText"
    issue
    location
  end
end
