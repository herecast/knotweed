# == Schema Information
#
# Table name: events
#
#  id             :integer          not null, primary key
#  event_type     :string(255)
#  venue_id       :integer
#  cost           :string(255)
#  event_url      :string(255)
#  sponsor        :string(255)
#  sponsor_url    :string(255)
#  links          :text
#  featured       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  contact_phone  :string(255)
#  contact_email  :string(255)
#  contact_url    :string(255)
#  cost_type      :string(255)
#  event_category :string(255)
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
    contact_phone "888-888-8888"
    contact_email "hello@fake.com"
    cost "$5"
    cost_type :free

    after(:build) do |e, evaluator|
      ei = FactoryGirl.create :event_instance, start_date: evaluator.start_date,
        subtitle_override: evaluator.subtitle_override, description_override: evaluator.description_override
      e.event_instances << ei
    end

  end
end
