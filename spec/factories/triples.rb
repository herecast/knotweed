# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :triple do
    dataset_id 1
    resource_class "MyString"
    resource_id 1
    resource_text "MyString"
    predicate "MyString"
    object_type "object"
    object_class "MyString"
    object_resource_id 1
    object_resource_text "MyString"
  end
end
