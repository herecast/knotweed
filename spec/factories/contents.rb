# == Schema Information
#
# Table name: contents
#
#  id                     :integer          not null, primary key
#  title                  :string(255)
#  subtitle               :string(255)
#  authors                :string(255)
#  raw_content            :text
#  issue_id               :integer
#  import_location_id     :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  copyright              :string(255)
#  guid                   :string(255)
#  pubdate                :datetime
#  source_category        :string(255)
#  topics                 :string(255)
#  summary                :text
#  url                    :string(255)
#  origin                 :string(255)
#  mimetype               :string(255)
#  language               :string(255)
#  page                   :string(255)
#  wordcount              :string(255)
#  authoremail            :string(255)
#  publication_id         :integer
#  file                   :string(255)
#  quarantine             :boolean          default(FALSE)
#  doctype                :string(255)
#  timestamp              :datetime
#  contentsource          :string(255)
#  import_record_id       :integer
#  source_content_id      :string(255)
#  parent_id              :integer
#  event_type             :string(255)
#  start_date             :datetime
#  end_date               :datetime
#  cost                   :string(255)
#  recurrence             :string(255)
#  links                  :text
#  host_organization      :string(255)
#  business_location_id   :integer
#  featured               :boolean          default(FALSE)
#  content_category_id    :integer
#  category_reviewed      :boolean          default(FALSE)
#  processed_content      :text
#  event_title            :string(255)
#  event_description      :text
#  event_url              :string(255)
#  sponsor_url            :string(255)
#  has_event_calendar     :boolean          default(FALSE)
#  channelized_content_id :integer
#  published              :boolean          default(FALSE)
#  channel_type           :string(255)
#  channel_id             :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title { "Title-#{[*('A'..'Z')].sample(8).join}" }
    subtitle "Subtitle"
    authors "John Smith"
    raw_content "Content goes here"
    publication
    issue
    import_location
    pubdate Time.now
    source_category "Category"
    content_category
  end
end
