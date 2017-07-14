# == Schema Information
#
# Table name: organizations
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  logo                :string(255)
#  organization_id     :integer
#  website             :string(255)
#  notes               :text
#  parent_id           :integer
#  org_type            :string(255)
#  can_reverse_publish :boolean          default(FALSE)
#  can_publish_news    :boolean          default(FALSE)
#  subscribe_url       :string(255)
#  description         :text
#  pay_rate_in_cents   :integer          default(0)
#  banner_ad_override  :string(255)
#  profile_title       :string(255)
#  pay_directly        :boolean          default(FALSE)
#  can_publish_events  :boolean          default(FALSE)
#  can_publish_market  :boolean          default(FALSE)
#  can_publish_talk    :boolean          default(FALSE)
#  can_publish_ads     :boolean          default(FALSE)
#  profile_image       :string(255)
#  background_image    :string(255)
#  profile_ad_override :string(255)
#  custom_links        :jsonb
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    sequence(:name) {|n| "My Organization #{n}" }
  end
end
