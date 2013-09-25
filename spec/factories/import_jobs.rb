# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_job do
    parser
    name "MyString"
    config "MyText"
    last_run_at "2013-09-24 16:59:50"
    source_path "MyString"
    organization
  end
end
