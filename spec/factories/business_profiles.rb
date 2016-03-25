# == Schema Information
#
# Table name: business_profiles
#
#  id                        :integer          not null, primary key
#  business_location_id      :integer
#  has_retail_location       :boolean          default(TRUE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  source                    :string(255)
#  source_id                 :integer
#  existence                 :integer
#  feedback_count            :integer          default(0)
#  feedback_recommend_avg    :float            default(0.0)
#  feedback_price_avg        :float            default(0.0)
#  feedback_satisfaction_avg :float            default(0.0)
#  feedback_cleanliness_avg  :float            default(0.0)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_profile do
    content
    business_location

    trait :with_feedback do
      after(:create) do |instance|
        create_list 5, :business_feedback, business_profile: instance
      end
    end
  end
end
