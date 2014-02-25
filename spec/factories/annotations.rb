# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :annotation do
    annotation_report_id 1
    annotation_id "MyString"
    accepted false
  end
end
