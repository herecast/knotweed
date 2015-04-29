# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_banner do
    promotion
    banner_image File.open("spec/fixtures/photo.jpg", "r")
    redirect_url "http://www.google.com"
  end
end
