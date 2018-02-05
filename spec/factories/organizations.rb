# == Schema Information
#
# Table name: organizations
#
#  id                       :integer          not null, primary key
#  name                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  logo                     :string(255)
#  organization_id          :integer
#  website                  :string(255)
#  notes                    :text
#  parent_id                :integer
#  org_type                 :string(255)
#  can_reverse_publish      :boolean          default(FALSE)
#  can_publish_news         :boolean          default(FALSE)
#  subscribe_url            :string(255)
#  description              :text
#  banner_ad_override       :string(255)
#  profile_title            :string(255)
#  pay_directly             :boolean          default(FALSE)
#  can_publish_events       :boolean          default(FALSE)
#  can_publish_market       :boolean          default(FALSE)
#  can_publish_talk         :boolean          default(FALSE)
#  can_publish_ads          :boolean          default(FALSE)
#  profile_image            :string(255)
#  background_image         :string(255)
#  profile_ad_override      :string(255)
#  twitter_handle           :string
#  custom_links             :jsonb
#  biz_feed_active          :boolean          default(FALSE)
#  ad_sales_agent           :string
#  ad_contact_nickname      :string
#  ad_contact_fullname      :string
#  profile_sales_agent      :string
#  blog_contact_name        :string
#  embedded_ad              :boolean          default(FALSE)
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
#
# Indexes
#
#  idx_16739_index_publications_on_name  (name) UNIQUE
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    sequence(:name) {|n| "My Organization #{n}" }
    biz_feed_active false
  end
end
