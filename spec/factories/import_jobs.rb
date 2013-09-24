# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_job do
    parser_id 1
    name "MyString"
    config "MyText"
    last_run_at "2013-09-24 16:59:50"
    source_path "MyString"
    type ""
  end
end
