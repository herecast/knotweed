# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title { "Title-#{[*('A'..'Z')].sample(8).join}" }
    subtitle "Subtitle"
    authors "John Smith"
    content "Content goes here"
    association :source, factory: :publication
    issue
    import_location
    pubdate Time.now
  end
end
