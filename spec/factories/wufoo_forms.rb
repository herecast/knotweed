# == Schema Information
#
# Table name: wufoo_forms
#
#  id             :integer          not null, primary key
#  form_hash      :string(255)
#  email_field    :string(255)
#  name           :string(255)
#  call_to_action :text
#  controller     :string(255)
#  action         :string(255)
#  active         :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

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
