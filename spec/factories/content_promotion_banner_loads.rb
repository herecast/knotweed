# == Schema Information
#
# Table name: content_promotion_banner_loads
#
#  id                  :integer          not null, primary key
#  content_id          :integer
#  promotion_banner_id :integer
#  load_count          :integer          default(1)
#  select_method       :string
#  select_score        :float
#  created_at          :datetime
#  updated_at          :datetime
#

FactoryGirl.define do
  factory :content_promotion_banner_load do
    content
    promotion_banner
    load_count 1
  end
end
