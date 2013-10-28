# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :issue do
    issue_edition "MyString"
    publication_date Time.now
    publication
    copyright "MyString"
  end
end
