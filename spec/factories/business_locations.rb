# == Schema Information
#
# Table name: business_locations
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  organization_id :integer
#  address         :string(255)
#  phone           :string(255)
#  email           :string(255)
#  hours           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_location do
    name "MyString"
    publication
    address "MyString"
    phone "MyString"
    email "MyString"
    hours "MyString"
  end
end
