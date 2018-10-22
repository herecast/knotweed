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
# Indexes
#
#  index_profile_metrics_on_client_id        (client_id)
#  index_profile_metrics_on_content_id       (content_id)
#  index_profile_metrics_on_event_type       (event_type)
#  index_profile_metrics_on_location_id      (location_id)
#  index_profile_metrics_on_organization_id  (organization_id)
#  index_profile_metrics_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
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
