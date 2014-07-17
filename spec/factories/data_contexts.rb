# == Schema Information
#
# Table name: data_contexts
#
#  id         :integer          not null, primary key
#  context    :string(255)
#  loaded     :boolean          default(FALSE)
#  last_load  :datetime
#  archived   :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :data_context do
    context "MyString"
    loaded false
    last_load "2014-02-20 18:27:03"
    archived false
  end
end
