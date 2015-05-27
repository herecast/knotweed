# == Schema Information
#
# Table name: promotion_banners
#
#  id           :integer          not null, primary key
#  banner_image :string(255)
#  redirect_url :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :promotion_banner do
    promotion
    redirect_url "http://www.google.com"
  end
end
