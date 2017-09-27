# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  banner          :string(255)
#  organization_id :integer
#  content_id      :integer
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :integer
#  promotable_type :string(255)
#  paid            :boolean          default(FALSE)
#  created_by      :integer
#  updated_by      :integer
#  share_platform  :string
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion do
    content
    description "What a nice promotion"
  end
end
