# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  listserv_id   :integer
#  community_ids :integer          default([]), is an Array
#  sponsored_by  :string
#  digest_query  :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  title         :string
#  preheader     :string
#  promotion_ids :integer          default([]), is an Array
#
# Indexes
#
#  index_campaigns_on_community_ids  (community_ids)
#  index_campaigns_on_listserv_id    (listserv_id)
#
# Foreign Keys
#
#  fk_rails_ac529cad68  (listserv_id => listservs.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign do
    sponsored_by "My String"
    listserv
    community_ids { [FactoryGirl.create(:location).id] }
  end
end
