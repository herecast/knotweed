# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  content_id  :integer
#  event_type  :string(255)
#  start_date  :datetime
#  end_date    :datetime
#  venue_id    :integer
#  cost        :string(255)
#  event_url   :string(255)
#  sponsor     :string(255)
#  sponsor_url :string(255)
#  links       :text
#  featured    :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    ignore do
      start_date 1.week.from_now
      subtitle_override nil
      description_override nil
    end

    content
    featured false
    association :venue, factory: :business_location

    after(:build) do |e, evaluator|
      ei = FactoryGirl.create :event_instance, start_date: evaluator.start_date,
        subtitle_override: evaluator.subtitle_override, description_override: evaluator.description_override
      e.event_instances << ei
    end

  end
end
