# == Schema Information
#
# Table name: contacts
#
#  id           :bigint(8)        not null, primary key
#  name         :string(255)
#  phone        :string(255)
#  email        :string(255)
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  contact_type :string(255)
#  address      :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    name "MyString"
    phone "MyString"
    email "MyString"
    notes "MyText"
    contact_type Contact::CONTACT_TYPES[0]
  end
end
