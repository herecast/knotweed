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
#  caster_id        :integer
#
# Indexes
#
#  index_organization_subscriptions_on_caster_id                    (caster_id)
#  index_organization_subscriptions_on_organization_id              (organization_id)
#  index_organization_subscriptions_on_user_id                      (user_id)
#  index_organization_subscriptions_on_user_id_and_organization_id  (user_id,organization_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

class CasterFollow < OrganizationSubscription
end