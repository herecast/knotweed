# frozen_string_literal: true

# == Schema Information
#
# Table name: business_feedbacks
#
#  id                  :bigint(8)        not null, primary key
#  created_by_id       :bigint(8)
#  updated_by_id       :bigint(8)
#  business_profile_id :bigint(8)
#  satisfaction        :boolean
#  cleanliness         :boolean
#  price               :boolean
#  recommend           :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_feedback do
    business_profile
    satisfaction true
    cleanliness true
    price true
    recommend true
  end
end
