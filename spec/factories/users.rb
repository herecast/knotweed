# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  default_repository_id  :integer
#  nda_agreed_at          :datetime
#  agreed_to_nda          :boolean          default(FALSE)
#  contact_phone          :string(255)
#  contact_email          :string(255)
#  contact_url            :string(255)
#  location_id            :integer
#  test_group             :string(255)      default("consumer")
#  muted                  :boolean          default(FALSE)
#  authentication_token   :string(255)
#  avatar                 :string(255)
#  public_id              :string(255)
#  skip_analytics         :boolean          default(FALSE)
#  temp_password          :string
#  archived               :boolean          default(FALSE)
#  source                 :string
#  receive_comment_alerts :boolean          default(TRUE)
#  location_confirmed     :boolean          default(FALSE)
#  fullname               :string
#  nickname               :string
#  epayment               :boolean          default(FALSE)
#  w9                     :boolean          default(FALSE)
#  has_had_bookmarks      :boolean          default(FALSE)
#  mc_segment_id          :string
#
# Indexes
#
#  idx_16858_index_users_on_email                 (email) UNIQUE
#  idx_16858_index_users_on_public_id             (public_id) UNIQUE
#  idx_16858_index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    name Faker::Name.name
    sequence(:email) {|n| "email#{n}@test.com" }
    password 'changeme'
    password_confirmation 'changeme'
    # required if the Devise Confirmable module is used
    confirmed_at Time.current
    location

    factory :admin do
      name 'Test Admin'
      after(:create) do |user|
        user.add_role :admin
      end
    end

    factory :organization_admin do
      name 'Test Organization Admin'
      after(:create) do |user|
        org = FactoryGirl.create :organization
        user.add_role :manager, org
      end
    end

  end
end
