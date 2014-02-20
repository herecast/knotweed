# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dataset do
    data_context
    name "MyString"
    description "MyString"
    realm "MyString"
    model_type "MyString"
  end
end
