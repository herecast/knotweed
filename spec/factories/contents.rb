# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title "Title"
    subtitle "Subtitle"
    authors "John Smith"
    content "Content goes here"
    association :source, factory: :publication
    issue
    location
    pubdate Time.now
  end
end
