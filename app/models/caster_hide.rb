# frozen_string_literal: true

# == Schema Information
#
# Table name: caster_hides
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  flag_type  :string
#  content_id :bigint(8)
#  caster_id  :integer
#
# Indexes
#
#  index_caster_hides_on_content_id  (content_id)
#  index_caster_hides_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#  fk_rails_...  (user_id => users.id)
#

class CasterHide < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :caster, optional: false

  validates :user_id, uniqueness: { scope: :caster_id }

  scope :active, -> { where(deleted_at: nil) }
end
