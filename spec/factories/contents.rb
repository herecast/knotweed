# == Schema Information
#
# Table name: contents
#
#  id                  :integer          not null, primary key
#  title               :string(255)
#  subtitle            :string(255)
#  authors             :string(255)
#  raw_content         :text
#  issue_id            :integer
#  import_location_id  :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  copyright           :string(255)
#  guid                :string(255)
#  pubdate             :datetime
#  source_category     :string(255)
#  topics              :string(255)
#  summary             :text
#  url                 :string(255)

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title { "Title-#{[*('A'..'Z')].sample(8).join}" }
    subtitle "Subtitle"
    authors "John Smith"
    raw_content "Content goes here"
    association :source, factory: :publication
    issue
    import_location
    pubdate Time.now
    source_category "Category"
    content_category
    channelized false
  end
end
