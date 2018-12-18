# frozen_string_literal: true

# == Schema Information
#
# Table name: content_metrics
#
#  id                 :integer          not null, primary key
#  content_id         :integer
#  event_type         :string
#  user_id            :integer
#  user_agent         :string
#  user_ip            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  client_id          :string
#  location_id        :integer
#  organization_id    :integer
#  location_confirmed :boolean          default(FALSE)
#
# Indexes
#
#  index_content_metrics_on_client_id        (client_id)
#  index_content_metrics_on_content_id       (content_id)
#  index_content_metrics_on_event_type       (event_type)
#  index_content_metrics_on_location_id      (location_id)
#  index_content_metrics_on_organization_id  (organization_id)
#  index_content_metrics_on_user_id          (user_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content_metric do
    content_id 1
  end
end
