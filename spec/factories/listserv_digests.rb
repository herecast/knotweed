# == Schema Information
#
# Table name: listserv_digests
#
#  id                   :integer          not null, primary key
#  listserv_id          :integer
#  listserv_content_ids :string
#  mc_campaign_id       :string
#  sent_at              :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  content_ids          :string
#  from_name            :string
#  reply_to             :string
#  subject              :string
#  template             :string
#  sponsored_by         :string
#  promotion_id         :integer
#  location_ids         :integer          default([]), is an Array
#  subscription_ids     :integer          default([]), is an Array
#  mc_segment_id        :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv_digest do
    listserv
    listserv_content_ids []
  end
end
