# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_recipients
#
#  id              :bigint(8)        not null, primary key
#  user_id         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_payment_recipients_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class PaymentRecipient < ActiveRecord::Base
  belongs_to :user

  validates_uniqueness_of :user
  validates_presence_of :user
end
