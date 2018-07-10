# == Schema Information
#
# Table name: business_categories
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :string(255)
#  icon_class  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  source      :string(255)
#  source_id   :integer
#
# Indexes
#
#  idx_16420_index_business_categories_on_source_and_source_id  (source,source_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :business_category do
    sequence(:name) { |n| "Biz Cat #{n}" }
    description "MyString"
    icon_class "MyString"
  end
end
