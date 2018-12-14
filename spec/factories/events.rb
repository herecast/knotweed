# == Schema Information
#
# Table name: events
#
#  id                    :bigint(8)        not null, primary key
#  event_type            :string(255)
#  venue_id              :bigint(8)
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
# Indexes
#
#  idx_16615_events_on_venue_id_index  (venue_id)
#  idx_16615_index_events_on_featured  (featured)
#  idx_16615_index_events_on_venue_id  (venue_id)
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
    end

    content {
      FactoryGirl.build(:content, :event, {
        channel: nil,
      }.tap do |attrs|
        if created_by
          attrs[:created_by] = created_by
        end
      end)
    }

    featured false
    association :venue, factory: :business_location
    contact_phone "888-888-8888"
    contact_email "hello@fake.com"
    cost "$5"
    cost_type :free

    after(:build) do |e, evaluator|
      unless evaluator.skip_event_instance
        ei = FactoryGirl.build :event_instance,
                               event: e,
                               start_date: evaluator.start_date,
                               subtitle_override: evaluator.subtitle_override, description_override: evaluator.description_override
        e.event_instances << ei
      end
    end
  end
end
