# frozen_string_literal: true
# == Schema Information
#
# Table name: ad_metrics
#
#  id         :integer          not null, primary key
#  campaign   :string
#  event_type :string
#  page_url   :string
#  content    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ad_metric do
    campaign 'CTA Below Death Star laser'
  end
end
