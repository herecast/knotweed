# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import_job do
    name "MyString"
    source_path "#{Rails.root}/lib/parsers/test/input"
    organization
  end
end
