# == Schema Information
#
# Table name: received_emails
#
#  id           :integer          not null, primary key
#  file_uri     :string
#  purpose      :string
#  processed_at :datetime
#  from         :string
#  to           :string
#  message_id   :string
#  record_id    :integer
#  record_type  :string
#  result       :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :received_email do
    file_uri "#{Rails.root}/spec/fixtures/emails/listserv_subscribe.eml"
    sequence(:to) {|n| "test#{n}@example.org" }
    sequence(:from) {|n| "user#{n}@example.org" }
  end
end
