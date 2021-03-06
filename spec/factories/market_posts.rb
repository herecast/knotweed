# frozen_string_literal: true

# == Schema Information
#
# Table name: market_posts
#
#  id                       :bigint(8)        not null, primary key
#  cost                     :string(255)
#  contact_phone            :string(255)
#  contact_email            :string(255)
#  contact_url              :string(255)
#  locate_name              :string(255)
#  locate_address           :string(255)
#  latitude                 :float
#  longitude                :float
#  locate_include_name      :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  status                   :string(255)
#  preferred_contact_method :string(255)
#  sold                     :boolean          default(FALSE)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :market_post do
    ignore do
      locations nil
      organization nil
      created_by nil
      title nil
    end

    cost '$5'
    contact_phone Faker::PhoneNumber.phone_number
    contact_email Faker::Internet.email
    contact_url Faker::Internet.url
    locate_name 'MP_locate_name'
    locate_address 'MP_locate_address'
    latitude Faker::Address.latitude
    longitude Faker::Address.longitude
    locate_include_name false
    content

    after(:build) do |e, evaluator|
      if e.content
        e.content.organization = evaluator.organization if evaluator.organization.present?
        e.content.created_by = evaluator.created_by if evaluator.created_by.present?
        e.content.title = evaluator.title if evaluator.title.present?
        e.content.content_category = 'market'
      end
    end
  end
end
