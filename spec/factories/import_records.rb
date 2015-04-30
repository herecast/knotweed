# == Schema Information
#
# Table name: import_records
#
#  id             :integer          not null, primary key
#  import_job_id  :integer
#  items_imported :integer          default(0)
#  failures       :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  filtered       :integer          default(0)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_record do
    import_job
  end
end
