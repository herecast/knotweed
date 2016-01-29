# == Schema Information
#
# Table name: content_promotion_banner_impressions
#
#  id                  :integer          not null, primary key
#  content_id          :integer
#  promotion_banner_id :integer
#  display_count       :integer          default(1)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  select_method       :string(255)
#  select_score        :float
#

FactoryGirl.define do
  factory :content_promotion_banner_impression do
    content
    promotion_banner
    display_count 1
  end
end
