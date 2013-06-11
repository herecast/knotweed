# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title "MyString"
    subtitle "MyString"
    authors "MyString"
    subject "MyString"
    content "MyText"
    issue_id 1
    location_id 1
  end
end
