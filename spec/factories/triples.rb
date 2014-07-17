# == Schema Information
#
# Table name: triples
#
#  id                   :integer          not null, primary key
#  dataset_id           :integer
#  resource_class       :string(255)
#  resource_id          :integer
#  resource_text        :string(255)
#  predicate            :string(255)
#  object_type          :string(255)
#  object_class         :string(255)
#  object_resource_id   :integer
#  object_resource_text :string(255)
#  realm                :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :triple do
    dataset_id 1
    resource_class "MyString"
    resource_id 1
    resource_text "MyString"
    predicate "MyString"
    object_type "object"
    object_class "MyString"
    object_resource_id 1
    object_resource_text "MyString"
  end
end
