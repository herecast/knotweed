# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :schedule do
    recurrence IceCube::Schedule.new(Time.now, end_time: 1.hour.from_now){ |s| s.add_recurrence_rule IceCube::Rule.daily.until(1.week.from_now) }.to_yaml
    event
  end
end
