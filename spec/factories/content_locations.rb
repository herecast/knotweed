# == Schema Information
#
# Table name: content_locations
#
#  id            :integer          not null, primary key
#  content_id    :integer
#  location_id   :integer
#  location_type :string
#  created_at    :datetime
#  updated_at    :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_location do
    content
    location
  end
end
