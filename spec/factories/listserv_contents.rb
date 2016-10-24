# == Schema Information
#
# Table name: listserv_contents
#
#  id                         :integer          not null, primary key
#  listserv_id                :integer
#  sender_name                :string(255)
#  sender_email               :string(255)
#  subject                    :string(255)
#  body                       :text(65535)
#  content_category_id        :integer
#  subscription_id            :integer
#  key                        :string(255)
#  verification_email_sent_at :datetime
#  verified_at                :datetime
#  pubdate                    :datetime
#  content_id                 :integer
#  user_id                    :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
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
