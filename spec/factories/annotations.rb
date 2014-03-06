# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :annotation do
    annotation_report
    annotation_id "an_0001"
    accepted false

    factory :lookup_annotation do
      lookup_class "LookupClassValue"
      is_trusted true
    end
  end
end
