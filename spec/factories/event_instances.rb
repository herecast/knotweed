# == Schema Information
#
# Table name: event_instances
#
#  id                   :integer          not null, primary key
#  event_id             :integer
#  start_date           :datetime
#  end_date             :datetime
#  subtitle_override    :string(255)
#  description_override :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  presenter_name       :string(255)
#  schedule_id          :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_instance do
    ignore do
      location false
      published true
    end

    start_date {1.week.from_now}

    event {
      build(:event,
        published: published,
        locations: location ? [ location ] : nil,
        skip_event_instance: true
      )
    }
  end
end
