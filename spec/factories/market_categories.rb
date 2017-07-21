# == Schema Information
#
# Table name: market_categories
#
#  id                 :integer          not null, primary key
#  name               :string
#  query              :string
#  category_image     :string
#  detail_page_banner :string
#  featured           :boolean          default(FALSE)
#  trending           :boolean          default(FALSE)
#  result_count       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  query_modifier     :string           default("AND")
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :market_category do
    sequence :name do |n|
      "Market Category #{n}"
    end
    query "Sample Query"
    category_image '/path/to/img'
    detail_page_banner '/path/to/bigger_image'
  end
end
