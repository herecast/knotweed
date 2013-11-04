# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_record do
    import_job_id 1
    items_imported 1
    failures 1
  end
end
