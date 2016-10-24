# == Schema Information
#
# Table name: listserv_contents
#
#  id                         :integer          not null, primary key
#  listserv_id                :integer
#  sender_name                :string
#  sender_email               :string
#  subject                    :string
#  body                       :text
#  content_category_id        :integer
#  subscription_id            :integer
#  key                        :string
#  verification_email_sent_at :datetime
#  verified_at                :datetime
#  pubdate                    :datetime
#  content_id                 :integer
#  user_id                    :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  verify_ip                  :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv_content do
    listserv
    subscription
    sequence(:sender_name) {|n| "Jim Bob the #{n.to_i.ordinalize}" }
    sequence(:sender_email) {|n| "user#{n}@example.org"}
    sequence(:subject) {|n| "Subject #{n}"}
    sequence(:body) {|n| "Body #{n}"}

    trait :verified do
      verify_ip '1.1.1.1'
      verified_at { Time.current }
    end
  end
end
