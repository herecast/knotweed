# frozen_string_literal: true

class UserMailer < ApplicationMailer
  add_template_helper EmailTemplateHelper

  def sign_in_link(sign_in_token)
    @auth_token = sign_in_token.token
    @user = sign_in_token.user

    mail to: @user.email, subject: 'Sign in to DailyUV.com'
  end

  def auto_subscribed(user:, password:)
    @password = password

    mail to: user.email, subject: 'Your free account on DailyUV is ready!'
  end
end
