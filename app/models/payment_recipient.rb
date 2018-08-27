# == Schema Information
#
# Table name: payment_recipients
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  alternative_emails :string
#  organization_id    :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_payment_recipients_on_organization_id  (organization_id)
#  index_payment_recipients_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_79c3a45f12  (organization_id => organizations.id)
#  fk_rails_87de0ab58e  (user_id => users.id)
#

class PaymentRecipient < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  validates_uniqueness_of :user
  validates_presence_of :user

end