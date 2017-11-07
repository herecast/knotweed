# == Schema Information
#
# Table name: profile_metrics
#
#  id                 :integer          not null, primary key
#  organization_id    :integer
#  location_id        :integer
#  user_id            :integer
#  content_id         :integer
#  event_type         :string
#  user_ip            :string
#  user_agent         :string
#  client_id          :string
#  location_confirmed :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :profile_metric do
    organization nil
    location nil
    user nil
    content nil
    event_type "MyString"
    user_ip "MyString"
    user_agent "MyString"
    client_id "MyString"
    location_confirmed false
  end
end
