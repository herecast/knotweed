# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :category_correction do
    content
    old_category "Old Cat"
    new_category "New Cat"
    user_email "testadmin@test.com"
  end
end
