# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json

  def create
    super do |user|
      if request.format.json?
        if [true, 'true'].include?(params[:instant_signup])
          user.location_id = Location.find_by(city: 'Hartford', state: 'VT').id
          user.confirmed_at = Time.current
          user.handle = params[:user][:handle]
          if user.save
            add_user_to_master_list(user)
            user.ensure_authentication_token
            render(json: payload(user), status: :created) && return
          else
            render(json: { errors: user.errors }, status: 422) && return
          end
        else
          res = {
            message: "Thank you! For security purposes, a message with a confirmation link has been sent to your email address. Please check your email and click on the link to activate your account. If the message hasn't appeared in a few minutes, please check your spam folder."
          }
          user.handle = params[:user][:handle]

          if user.save
            render(json: res, status: 201) && return
          else
            render(json: { errors: user.errors }, status: 422) && return
          end
        end
      end
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :name,
      :email,
      :location_id,
      :password,
      :password_confirmation
    )
  end

  def payload(user)
    {
      token: user.authentication_token,
      email: user.email
    }
  end

  def account_update_params
    params.require(:user).permit(
      :name,
      :email,
      :location_id,
      :password,
      :password_confirmation,
      :current_password
    )
  end

  def add_user_to_master_list(user)
    BackgroundJob.perform_later(
      'Outreach::AddUserToMailchimpMasterList',
      'call',
      user,
      new_blogger: true
    )
  end
end
