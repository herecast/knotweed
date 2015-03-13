# == Schema Information
#
# Table name: market_posts
#
#  id                  :integer          not null, primary key
#  cost                :string(255)
#  contact_phone       :string(255)
#  contact_email       :string(255)
#  contact_url         :string(255)
#  locate_name         :string(255)
#  locate_address      :string(255)
#  latitude            :float
#  longitude           :float
#  locate_include_name :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :market_post do
    cost "MyString"
    contact_phone "MyString"
    contact_email "MyString"
    contact_url "MyString"
    locate_name "MyString"
    locate_address "MyString"
    latitude 1.5
    longitude 1.5
    locate_include_name false
  end
end
