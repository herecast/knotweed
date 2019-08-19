# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_recipients
#
#  id              :bigint(8)        not null, primary key
#  user_id         :integer
#  organization_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_payment_recipients_on_organization_id  (organization_id)
#  index_payment_recipients_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

require 'rails_helper'

RSpec.describe PaymentRecipient, type: :model do
end
