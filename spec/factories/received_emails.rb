# == Schema Information
#
# Table name: received_emails
#
#  id           :integer          not null, primary key
#  file_uri     :string(255)
#  purpose      :string(255)
#  processed_at :datetime
#  from         :string(255)
#  to           :string(255)
#  message_id   :string(255)
#  record_id    :integer
#  record_type  :string(255)
#  result       :string(255)
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
