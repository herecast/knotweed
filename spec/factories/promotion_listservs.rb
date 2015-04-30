# == Schema Information
#
# Table name: promotion_listservs
#
#  id          :integer          not null, primary key
#  listserv_id :integer
#  sent_at     :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_listserv do
    listserv
    sent_at "2015-04-30 14:37:06"
  end
end
