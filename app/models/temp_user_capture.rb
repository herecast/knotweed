class TempUserCapture < ActiveRecord::Base
  validate :new_user?

  def new_user?
    if User.find_by_email(email).present?
      self.errors[:base] << "Email already registered"
    end
  end
end
