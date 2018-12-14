# frozen_string_literal: true

# == Schema Information
#
# Table name: subscriptions
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  listserv_id          :integer
#  confirmed_at         :datetime
#  unsubscribed_at      :datetime
#  blacklist            :boolean          default(FALSE)
#  subscription_details :string
#  source               :string
#  email                :string           not null
#  confirmation_details :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  key                  :string           not null
#  name                 :string
#  confirm_ip           :string
#  email_type           :string           default("html")
#  mc_unsubscribed_at   :datetime
#
# Indexes
#
#  index_subscriptions_on_listserv_id  (listserv_id)
#  index_subscriptions_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (listserv_id => listservs.id)
#  fk_rails_...  (user_id => users.id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :subscription do
    user
    listserv
    source 'email'
    sequence(:email) { |n| "user#{n}@example.org" }
    name 'Da Name'

    trait(:confirmed) do
      confirmed_at { 1.day.ago }
      confirm_ip '1.1.1.1'
    end

    trait(:subscribed) do
      confirmed_at { 1.day.ago }
      confirm_ip '1.1.1.1'
      unsubscribed_at nil
    end

    trait(:unsubscribed) do
      unsubscribed_at { Time.current }
    end
  end
end
