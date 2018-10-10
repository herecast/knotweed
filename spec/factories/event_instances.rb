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
# Indexes
#
#  idx_16625_index_event_instances_on_end_date    (end_date)
#  idx_16625_index_event_instances_on_event_id    (event_id)
#  idx_16625_index_event_instances_on_start_date  (start_date)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_instance do
    ignore do
      location false
    end

    start_date {1.week.from_now}

    event {
      build(:event,
        locations: location ? [ location ] : nil,
        skip_event_instance: true
      )
    }
  end
end
