# == Schema Information
#
# Table name: contents
#
#  id                 :integer          not null, primary key
#  title              :string(255)
#  subtitle           :string(255)
#  authors            :string(255)
#  content            :text
#  issue_id           :integer
#  import_location_id :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  copyright          :string(255)
#  guid               :string(255)
#  pubdate            :datetime
#  categories         :string(255)
#  topics             :string(255)
#  summary            :text
#  url                :string(255)
#  origin             :string(255)
#  mimetype           :string(255)
#  language           :string(255)
#  page               :string(255)
#  wordcount          :string(255)
#  authoremail        :string(255)
#  source_id          :integer
#  file               :string(255)
#  quarantine         :boolean          default(FALSE)
#  doctype            :string(255)
#  timestamp          :datetime
#  contentsource      :string(255)
#  import_record_id   :integer
#  source_content_id  :string(255)
#  image              :string(400)
#  parent_id          :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :content do
    title { "Title-#{[*('A'..'Z')].sample(8).join}" }
    subtitle "Subtitle"
    authors "John Smith"
    content "Content goes here"
    association :source, factory: :publication
    issue
    import_location
    pubdate Time.now
  end
end
