# frozen_string_literal: true

# == Schema Information
#
# Table name: event_instances
#
#  id                   :bigint(8)        not null, primary key
#  event_id             :bigint(8)
#  start_date           :datetime
#  end_date             :datetime
#  subtitle_override    :string(255)
#  description_override :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  presenter_name       :string(255)
#  schedule_id          :bigint(8)
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

    start_date { 1.week.from_now }

    event do
      build(:event,
            location: location,
            skip_event_instance: true)
    end
  end
end
