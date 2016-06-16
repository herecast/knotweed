# == Schema Information
#
# Table name: schedules
#
#  id                   :integer          not null, primary key
#  recurrence           :text
#  event_id             :integer
#  description_override :text
#  subtitle_override    :string(255)
#  presenter_name       :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :schedule do
    recurrence IceCube::Schedule.new(Time.current, end_time: 1.hour.from_now){ |s| s.add_recurrence_rule IceCube::Rule.daily.until(1.week.from_now) }.to_yaml
    event
  end
end
