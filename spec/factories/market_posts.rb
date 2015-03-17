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
    cost "MP_cost"
    contact_phone "MP_contact_phone"
    contact_email "MP_contact_email"
    contact_url "MP_contact_url"
    locate_name "MP_locate_name"
    locate_address "MP_locate_address"
    latitude 1.5
    longitude 1.5
    locate_include_name false
    content
  end
end
