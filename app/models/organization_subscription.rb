# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_subscriptions
#
#  id               :bigint(8)        not null, primary key
#  user_id          :bigint(8)
#  organization_id  :bigint(8)
#  mc_subscriber_id :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deleted_at       :datetime
#
# Indexes
#
#  index_organization_subscriptions_on_organization_id              (organization_id)
#  index_organization_subscriptions_on_user_id                      (user_id)
#  index_organization_subscriptions_on_user_id_and_organization_id  (user_id,organization_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

class OrganizationSubscription < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :organization, optional: false
  validates :user_id, uniqueness: { scope: :organization_id }

  scope :active, -> { where(deleted_at: nil) }

  def create_in_mailchimp
    Outreach::CreateOrganizationSubscriptionInMailchimp.call(self)
  end

  def destroy_in_mailchimp
    Outreach::DestroyOrganizationSubscriptionInMailchimp.call(self)
  end
end
