# frozen_string_literal: true

# == Schema Information
#
# Table name: business_profiles
#
#  id                        :bigint(8)        not null, primary key
#  business_location_id      :bigint(8)
#  has_retail_location       :boolean          default(TRUE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  source                    :string(255)
#  source_id                 :string(255)
#  existence                 :float
#  feedback_count            :bigint(8)        default(0)
#  feedback_recommend_avg    :float            default(0.0)
#  feedback_price_avg        :float            default(0.0)
#  feedback_satisfaction_avg :float            default(0.0)
#  feedback_cleanliness_avg  :float            default(0.0)
#  archived                  :boolean          default(FALSE)
#
# Indexes
#
#  idx_16451_index_business_profiles_on_existence             (existence)
#  idx_16451_index_business_profiles_on_source_and_source_id  (source,source_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_profile do
    business_location

    trait :with_feedback do
      after(:create) do |instance|
        create_list 5, :business_feedback, business_profile: instance
      end
    end

    # out of the box, business profiles are "unclaimed" and don't have associated
    # content records. Once claimed, we generate a content and organization
    trait :claimed do
      content
    end
  end
end
