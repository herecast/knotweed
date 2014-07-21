# == Schema Information
#
# Table name: datasets
#
#  id              :integer          not null, primary key
#  data_context_id :integer
#  name            :string(255)
#  description     :string(255)
#  realm           :string(255)
#  model_type      :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dataset do
    data_context
    name "MyString"
    description "MyString"
    realm "MyString"
    model_type "MyString"
  end
end
