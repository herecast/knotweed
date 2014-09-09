# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :wufoo_form do
    form_hash "MyString"
    email_field "MyString"
    name "MyString"
    call_to_action "MyString"
    controller "MyString"
    action "MyString"
    active false
  end
end
