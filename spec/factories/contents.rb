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
#  my_town_only              :boolean          default(FALSE)
#  authors_is_created_by     :boolean          default(FALSE)
#  subscriber_mc_identifier  :string
#  biz_feed_public           :boolean
#  sunset_date               :datetime
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
    import_location
    pubdate {Time.current}
    source_category "Category"
    content_category
    authoremail 'fake@email.com'
    published false

    trait :talk do
      content_category {
        ContentCategory.find_or_create_by({
          name: 'talk_of_the_town'
        })
      }
    end

    trait :news do
      content_category {
        ContentCategory.find_or_create_by({
          name: 'news'
        })
      }
    end

    trait :event do
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
      content_category {
        ContentCategory.find_or_create_by({
          name: 'market'
        })
      }

      channel {
        FactoryGirl.build :market_post, content: nil
      }
    end

    trait :published do
      published true
      pubdate { Time.current }
    end
  end
end
