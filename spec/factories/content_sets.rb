# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_set do
    publication
    name "MyString"
    description "MyText"
    notes "MyText"
    status "MyString"
    import_method ContentSet::IMPORT_METHODS[0]
  end
end
