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
