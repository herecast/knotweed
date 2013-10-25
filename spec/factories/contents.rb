# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title "MyString"
    subtitle "MyString"
    authors "MyString"
    content "MyText"
    association :contentsource, factory: :publication
    issue
    location
  end
end
