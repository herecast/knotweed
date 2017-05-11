class UserPreview < ActionMailer::Preview
  def sign_in_link
    UserMailer.sign_in_link(
      FactoryGirl.build(:sign_in_token,
        user: FactoryGirl.build(:user)
      )
    )
  end
end
