# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  banner          :string(255)
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
# Indexes
#
#  idx_16765_index_promotions_on_content_id  (content_id)
#  idx_16765_index_promotions_on_created_by  (created_by)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion do
    content
    description "What a nice promotion"
  end
end
