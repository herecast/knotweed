# == Schema Information
#
# Table name: temp_user_captures
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TempUserCapture < ActiveRecord::Base
  validate :new_user?

  def new_user?
    if User.find_by_email(email).present?
      self.errors[:base] << "Email already registered"
    end
  end
end
