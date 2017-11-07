# == Schema Information
#
# Table name: content_metrics
#
#  id              :integer          not null, primary key
#  content_id      :integer
#  event_type      :string
#  user_id         :integer
#  user_agent      :string
#  user_ip         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :string
#  location_id     :integer
#  organization_id :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_metric do
    content_id 1
  end
end
