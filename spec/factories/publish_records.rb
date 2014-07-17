# == Schema Information
#
# Table name: publish_records
#
#  id              :integer          not null, primary key
#  publish_job_id  :integer
#  items_published :integer          default(0)
#  failures        :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :publish_record do
    publish_job nil
    items_published 1
    failures 1
  end
end
