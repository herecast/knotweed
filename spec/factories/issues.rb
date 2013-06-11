# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :issue do
    issue_edition "MyString"
    publication_date "2013-06-11"
    publication_id 1
    copyright "MyString"
  end
end
