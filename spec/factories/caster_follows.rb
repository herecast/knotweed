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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :caster_follow do
    user
    caster
  end
end
