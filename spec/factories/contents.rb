# == Schema Information
#
# Table name: contents
#
#  id                        :integer          not null, primary key
#  title                     :string(255)
#  subtitle                  :string(255)
#  authors                   :string(255)
#  raw_content               :text
#  issue_id                  :integer
#  import_location_id        :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  copyright                 :string(255)
#  guid                      :string(255)
#  pubdate                   :datetime
#  source_category           :string(255)
#  topics                    :string(255)
#  url                       :string(255)
#  origin                    :string(255)
#  language                  :string(255)
#  page                      :string(255)
#  authoremail               :string(255)
#  organization_id           :integer
#  quarantine                :boolean          default(FALSE)
#  doctype                   :string(255)
#  timestamp                 :datetime
#  contentsource             :string(255)
#  import_record_id          :integer
#  source_content_id         :string(255)
#  parent_id                 :integer
#  content_category_id       :integer
#  category_reviewed         :boolean          default(FALSE)
#  has_event_calendar        :boolean          default(FALSE)
#  channelized_content_id    :integer
#  published                 :boolean          default(FALSE)
#  channel_type              :string(255)
#  channel_id                :integer
#  root_content_category_id  :integer
#  view_count                :integer          default(0)
#  comment_count             :integer          default(0)
#  commenter_count           :integer          default(0)
#  created_by                :integer
#  updated_by                :integer
#  banner_click_count        :integer          default(0)
#  similar_content_overrides :text
#  banner_ad_override        :integer
#  root_parent_id            :integer
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
#  ugc_job                   :string
#  ad_invoice_paid           :boolean          default(FALSE)
#  ad_commission_amount      :float
#  ad_commission_paid        :boolean          default(FALSE)
#  ad_services_amount        :float
#  ad_services_paid          :boolean          default(FALSE)
#  ad_sales_agent            :integer
#  ad_promoter               :integer
#  latest_activity           :datetime
#  alternate_title           :string
#  alternate_organization_id :integer
#  alternate_authors         :string
#  alternate_text            :string
#  alternate_image_url       :string
#
# Indexes
#
#  idx_16527_authors                                     (authors)
#  idx_16527_categories                                  (source_category)
#  idx_16527_content_category_id                         (content_category_id)
#  idx_16527_guid                                        (guid)
#  idx_16527_import_record_id                            (import_record_id)
#  idx_16527_index_contents_on_authoremail               (authoremail)
#  idx_16527_index_contents_on_channel_id                (channel_id)
#  idx_16527_index_contents_on_channel_type              (channel_type)
#  idx_16527_index_contents_on_channelized_content_id    (channelized_content_id)
#  idx_16527_index_contents_on_created_by                (created_by)
#  idx_16527_index_contents_on_parent_id                 (parent_id)
#  idx_16527_index_contents_on_published                 (published)
#  idx_16527_index_contents_on_root_content_category_id  (root_content_category_id)
#  idx_16527_index_contents_on_root_parent_id            (root_parent_id)
#  idx_16527_location_id                                 (import_location_id)
#  idx_16527_pubdate                                     (pubdate)
#  idx_16527_source_id                                   (organization_id)
#  idx_16527_title                                       (title)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title { "Title-#{[*('A'..'Z')].sample(8).join}" }
    subtitle "Subtitle"
    authors Faker::Name.name
    raw_content "Content goes here"
    organization
    issue
    pubdate {Time.current}
    source_category "Category"
    content_category
    authoremail 'fake@email.com'
    published true
    created_by { FactoryGirl.build(:user) }

    trait :located do
      content_locations {
        [FactoryGirl.build(:content_location,  content: nil)]
      }
    end

    trait :talk do
      located
      channel {
        FactoryGirl.build :comment, content: nil
      }
      content_category {
        ContentCategory.find_or_create_by({
          name: 'talk_of_the_town'
        })
      }
    end

    trait :news do
      located
      content_category {
        ContentCategory.find_or_create_by({
          name: 'news'
        })
      }
    end

    trait :event do
      located
      content_category {
        ContentCategory.find_or_create_by({
          name: 'event'
        })
      }

      channel {
        FactoryGirl.build :event, content: nil
      }
    end

    trait :market_post do
      located
      content_category {
        ContentCategory.find_or_create_by({
          name: 'market'
        })
      }

      channel {
        FactoryGirl.build :market_post, content: nil
      }
    end

    trait :comment do
      channel_type 'Comment'
      parent_id 0
      channel {
        FactoryGirl.build :comment, content: nil
      }
    end

    trait :published do
      published true
      pubdate { Time.current }
    end

    trait :campaign do
      ad_promotion_type 'ROS'
      ad_campaign_start Date.yesterday
      ad_campaign_end Date.tomorrow
      content_category {
        ContentCategory.find_or_create_by({
          name: 'campaign'
        })
      }
    end
  end
end
