# == Schema Information
#
# Table name: listserv_digests
#
#  id               :integer          not null, primary key
#  listserv_id      :integer
#  mc_campaign_id   :string
#  sent_at          :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  from_name        :string
#  reply_to         :string
#  subject          :string
#  template         :string
#  sponsored_by     :string
#  location_ids     :integer          default([]), is an Array
#  subscription_ids :integer          default([]), is an Array
#  mc_segment_id    :string
#  title            :string
#  preheader        :string
#  promotion_ids    :integer          default([]), is an Array
#  content_ids      :integer          is an Array
#  emails_sent      :integer          default(0), not null
#  opens_total      :integer          default(0), not null
#  link_clicks      :hstore           default({}), not null
#  last_mc_report   :datetime
#
# Indexes
#
#  index_listserv_digests_on_listserv_id  (listserv_id)
#
# Foreign Keys
#
#  fk_rails_386f862ec4  (listserv_id => listservs.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :listserv_digest do
    listserv
  end
end
