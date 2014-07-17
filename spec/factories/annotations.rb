# == Schema Information
#
# Table name: annotations
#
#  id                   :integer          not null, primary key
#  annotation_report_id :integer
#  annotation_id        :string(255)
#  accepted             :boolean
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  startnode            :string(255)
#  endnode              :string(255)
#  annotation_type      :string(255)
#  is_generated         :boolean
#  lookup_class         :string(255)
#  token_feature        :string(255)
#  recognized_class     :string(255)
#  annotated_string     :string(255)
#  instance             :string(255)
#  edges                :text
#  is_trusted           :boolean
#  rule                 :string(255)
#

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
