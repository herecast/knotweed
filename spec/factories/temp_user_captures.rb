# == Schema Information
#
# Table name: temp_user_captures
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :temp_user_capture do
    name Faker::Name.name
    sequence(:email) { |i| "temp_user_#{i}@test.com" }
  end
end
