# frozen_string_literal: true

# == Schema Information
#
# Table name: contents
#
#  id                        :bigint(8)        not null, primary key
#  title                     :string(255)
#  subtitle                  :string(255)
#  authors                   :string(255)
#  raw_content               :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  guid                      :string(255)
#  pubdate                   :datetime
#  url                       :string(255)
#  origin                    :string(255)
#  page                      :string(255)
#  authoremail               :string(255)
#  organization_id           :bigint(8)
#  quarantine                :boolean          default(FALSE)
#  timestamp                 :datetime
#  parent_id                 :bigint(8)
#  content_category_id       :bigint(8)
#  has_event_calendar        :boolean          default(FALSE)
#  channelized_content_id    :bigint(8)
#  channel_type              :string(255)
#  channel_id                :bigint(8)
#  root_content_category_id  :bigint(8)
#  view_count                :bigint(8)        default(0)
#  comment_count             :bigint(8)        default(0)
#  commenter_count           :bigint(8)        default(0)
#  created_by_id             :bigint(8)
#  updated_by_id             :bigint(8)
#  banner_click_count        :bigint(8)        default(0)
#  similar_content_overrides :text
#  banner_ad_override        :bigint(8)
#  root_parent_id            :bigint(8)
#  deleted_at                :datetime
#  authors_is_created_by     :boolean          default(FALSE)
#  subscriber_mc_identifier  :string
#  biz_feed_public           :boolean
#  sunset_date               :datetime
#  promote_radius            :integer
#  ad_promotion_type         :string
#  ad_campaign_start         :date
#  ad_campaign_end           :date
#  ad_max_impressions        :integer
#  short_link                :string
#  ad_invoiced_amount        :float
#  first_served_at           :datetime
#  removed                   :boolean          default(FALSE)
#  ad_invoice_paid           :boolean          default(FALSE)
#  ad_commission_amount      :float
#  ad_commission_paid        :boolean          default(FALSE)
#  ad_services_amount        :float
#  ad_services_paid          :boolean          default(FALSE)
#  ad_sales_agent            :integer
#  ad_promoter               :integer
#  latest_activity           :datetime
#  has_future_event_instance :boolean
#  alternate_title           :string
#  alternate_organization_id :integer
#  alternate_authors         :string
#  alternate_text            :string
#  alternate_image_url       :string
#  location_id               :integer
#  mc_campaign_id            :string
#
# Indexes
#
#  idx_16527_authors                                     (authors)
#  idx_16527_content_category_id                         (content_category_id)
#  idx_16527_guid                                        (guid)
#  idx_16527_index_contents_on_authoremail               (authoremail)
#  idx_16527_index_contents_on_channel_id                (channel_id)
#  idx_16527_index_contents_on_channel_type              (channel_type)
#  idx_16527_index_contents_on_channelized_content_id    (channelized_content_id)
#  idx_16527_index_contents_on_created_by                (created_by_id)
#  idx_16527_index_contents_on_parent_id                 (parent_id)
#  idx_16527_index_contents_on_root_content_category_id  (root_content_category_id)
#  idx_16527_index_contents_on_root_parent_id            (root_parent_id)
#  idx_16527_pubdate                                     (pubdate)
#  idx_16527_source_id                                   (organization_id)
#  idx_16527_title                                       (title)
#  index_contents_on_location_id                         (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title { "Title-#{[*('A'..'Z')].sample(8).join}" }
    subtitle 'Subtitle'
    authors Faker::Name.name
    raw_content 'Content goes here'
    organization
    pubdate { Time.current }
    content_category
    authoremail 'fake@email.com'
    created_by { FactoryGirl.build(:user) }

    trait :located do
      location do
        FactoryGirl.build :location
      end
    end

    trait :talk do
      located
      channel do
        FactoryGirl.build :comment, content: nil
      end
      content_category do
        ContentCategory.find_or_create_by(
          name: 'talk_of_the_town'
        )
      end
    end

    trait :news do
      located
      content_category do
        ContentCategory.find_or_create_by(
          name: 'news'
        )
      end
    end

    trait :event do
      located
      content_category do
        ContentCategory.find_or_create_by(
          name: 'event'
        )
      end

      channel do
        FactoryGirl.build :event, content: nil
      end
    end

    trait :market_post do
      located
      content_category do
        ContentCategory.find_or_create_by(
          name: 'market'
        )
      end

      channel do
        FactoryGirl.build :market_post, content: nil
      end
    end

    trait :comment do
      channel_type 'Comment'
      parent_id 0
      channel do
        FactoryGirl.build :comment, content: nil
      end
    end

    trait :published do
      pubdate { Time.current }
    end

    trait :campaign do
      ad_promotion_type 'ROS'
      ad_campaign_start Date.yesterday
      ad_campaign_end 1.month.from_now
      content_category do
        ContentCategory.find_or_create_by(
          name: 'campaign'
        )
      end
    end
  end
end
