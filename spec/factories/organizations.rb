# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  id                       :bigint(8)        not null, primary key
#  name                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  logo                     :string(255)
#  organization_id          :bigint(8)
#  website                  :string(255)
#  notes                    :text
#  parent_id                :bigint(8)
#  org_type                 :string(255)
#  can_reverse_publish      :boolean          default(FALSE)
#  can_publish_news         :boolean          default(FALSE)
#  description              :text
#  banner_ad_override       :string(255)
#  pay_directly             :boolean          default(FALSE)
#  profile_image            :string(255)
#  background_image         :string(255)
#  twitter_handle           :string
#  custom_links             :jsonb
#  biz_feed_active          :boolean          default(FALSE)
#  ad_sales_agent           :string
#  ad_contact_nickname      :string
#  ad_contact_fullname      :string
#  profile_sales_agent      :string
#  certified_storyteller    :boolean          default(FALSE)
#  services                 :string
#  contact_card_active      :boolean          default(TRUE)
#  description_card_active  :boolean          default(TRUE)
#  hours_card_active        :boolean          default(TRUE)
#  pay_for_content          :boolean          default(FALSE)
#  special_link_url         :string
#  special_link_text        :string
#  certified_social         :boolean          default(FALSE)
#  desktop_image            :string
#  archived                 :boolean          default(FALSE)
#  feature_notification_org :boolean          default(FALSE)
#  standard_ugc_org         :boolean          default(FALSE)
#  calendar_view_first      :boolean          default(FALSE)
#  calendar_card_active     :boolean          default(FALSE)
#  embedded_ad              :boolean          default(TRUE)
#  digest_id                :integer
#  reminder_campaign_id     :string
#  mc_segment_id            :string
#
# Indexes
#
#  idx_16739_index_publications_on_name  (name) UNIQUE
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    sequence(:name) { |n| "My Organization #{n}" }
    biz_feed_active false

    trait :default do
      name "From HereCast"
      standard_ugc_org true
    end
  end
end
