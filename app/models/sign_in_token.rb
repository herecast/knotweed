# == Schema Information
#
# Table name: sign_in_tokens
#
#  id         :integer          not null, primary key
#  token      :string           not null
#  user_id    :integer
#  created_at :datetime         not null
#

class SignInToken < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user

  after_initialize :generate_token

  def self.authenticate(token)
    self.includes(:user)\
      .where('sign_in_tokens.created_at >= ?', 24.hours.ago)\
      .find_by(token: token)\
      .try(:user)
  end

  def self.clean_stale!
    self.where('created_at < ?', 24.hours.ago).delete_all
  end

  private
  def generate_token
    self.token ||= SecureRandom.hex(10)
  end
end
