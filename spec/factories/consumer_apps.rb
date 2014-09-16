# == Schema Information
#
# Table name: consumer_apps
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  uri           :string(255)
#  repository_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :consumer_app do
    name "Test App"
    uri "http://23.92.16.168:1234"
  end
end
