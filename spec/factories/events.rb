# == Schema Information
#
# Table name: events
#
#  id                    :integer          not null, primary key
#  event_type            :string(255)
#  venue_id              :integer
#  cost                  :string(255)
#  event_url             :string
#  sponsor               :string(255)
#  sponsor_url           :string(255)
#  links                 :text
#  featured              :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  contact_phone         :string(255)
#  contact_email         :string(255)
#  cost_type             :string(255)
#  event_category        :string(255)
#  social_enabled        :boolean          default(FALSE)
#  registration_deadline :datetime
#  registration_url      :string(255)
#  registration_phone    :string(255)
#  registration_email    :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    ignore do
      start_date 1.week.from_now
      subtitle_override nil
      description_override nil
      skip_event_instance false
      created_by nil
      published false
      locations nil
      content_locations nil
    end

    association :content, :event, channel: nil
    featured false
    association :venue, factory: :business_location
    contact_phone "888-888-8888"
    contact_email "hello@fake.com"
    cost "$5"
    cost_type :free

    after(:build) do |e, evaluator|
      unless evaluator.skip_event_instance
        ei = FactoryGirl.create :event_instance, start_date: evaluator.start_date,
          subtitle_override: evaluator.subtitle_override, description_override: evaluator.description_override
        e.event_instances << ei
      end

      if e.content
        if ContentCategory.exists?(name: 'event')
          e.content.content_category = ContentCategory.find_by name: 'event'
        else
          e.content.content_category = FactoryGirl.build :content_category, name: 'event'
        end
        e.content.published = evaluator.published
        e.content.created_by = evaluator.created_by if evaluator.created_by.present?

        if evaluator.locations
          e.content.content_locations = []
          evaluator.locations.each do |location|
            e.content.content_locations << ContentLocation.new(
              location: location
            )
          end
        elsif evaluator.content_locations
          e.content.content_locations = evaluator.content_locations
        end
      end
    end

  end
end
