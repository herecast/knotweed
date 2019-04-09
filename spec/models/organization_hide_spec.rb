# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_hides
#
#  id              :bigint(8)        not null, primary key
#  user_id         :bigint(8)
#  organization_id :bigint(8)
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  flag_type       :string
#  content_id      :bigint(8)
#
# Indexes
#
#  index_organization_hides_on_content_id       (content_id)
#  index_organization_hides_on_organization_id  (organization_id)
#  index_organization_hides_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

require 'rails_helper'

RSpec.describe OrganizationHide, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end