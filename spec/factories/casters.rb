# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                               :bigint(8)        not null, primary key
#  email                            :string(255)      default(""), not null
#  encrypted_password               :string(255)      default(""), not null
#  reset_password_token             :string(255)
#  reset_password_sent_at           :datetime
#  remember_created_at              :datetime
#  sign_in_count                    :bigint(8)        default(0)
#  current_sign_in_at               :datetime
#  last_sign_in_at                  :datetime
#  current_sign_in_ip               :string(255)
#  last_sign_in_ip                  :string(255)
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  name                             :string(255)
#  confirmation_token               :string(255)
#  confirmed_at                     :datetime
#  confirmation_sent_at             :datetime
#  unconfirmed_email                :string(255)
#  contact_phone                    :string(255)
#  contact_email                    :string(255)
#  location_id                      :bigint(8)
#  authentication_token             :string(255)
#  avatar                           :string(255)
#  public_id                        :string(255)
#  skip_analytics                   :boolean          default(FALSE)
#  archived                         :boolean          default(FALSE)
#  source                           :string
#  receive_comment_alerts           :boolean          default(TRUE)
#  location_confirmed               :boolean          default(FALSE)
#  fullname                         :string
#  nickname                         :string
#  epayment                         :boolean          default(FALSE)
#  w9                               :boolean          default(FALSE)
#  has_had_bookmarks                :boolean          default(FALSE)
#  mc_segment_id                    :string
#  first_name                       :string
#  last_name                        :string
#  feed_card_size                   :string
#  publisher_agreement_confirmed    :boolean          default(FALSE)
#  publisher_agreement_confirmed_at :datetime
#  publisher_agreement_version      :string
#  handle                           :string
#  mc_followers_segment_id          :string
#  email_is_public                  :boolean          default(FALSE)
#  background_image                 :string
#  description                      :string
#  website                          :string
#  phone                            :string
#
# Indexes
#
#  idx_16858_index_users_on_email                 (email) UNIQUE
#  idx_16858_index_users_on_public_id             (public_id) UNIQUE
#  idx_16858_index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :caster do
    name Faker::Name.name
    fullname Faker::Name.name
    email { "email-#{rand(500)}@test.com" }
    handle { "handle-#{rand(500)}" }
    password 'changeme'
    password_confirmation 'changeme'
    confirmed_at Time.current
    location
  end
end
