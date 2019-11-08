# frozen_string_literal: true

# == Schema Information
#
# Table name: caster_follows
#
#  id               :bigint(8)        not null, primary key
#  user_id          :bigint(8)
#  mc_subscriber_id :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deleted_at       :datetime
#  caster_id        :integer
#
# Indexes
#
#  index_caster_follows_on_caster_id              (caster_id)
#  index_caster_follows_on_user_id                (user_id)
#  index_caster_follows_on_user_id_and_caster_id  (user_id,caster_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (caster_id => casters.id)
#  fk_rails_...  (user_id => users.id)
#

class CasterFollow < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :caster, optional: false

  validates :user_id, uniqueness: { scope: :caster_id }

  scope :active, -> { where(deleted_at: nil) }

  def create_in_mailchimp
    Outreach::CreateCasterFollowInMailchimp.call(self)
  end

  def destroy_in_mailchimp
    Outreach::DestroyCasterFollowInMailchimp.call(self)
  end
end
