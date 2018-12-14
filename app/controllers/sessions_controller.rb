class SessionsController < Devise::SessionsController
  respond_to :html, :json

  def create
    super do |user|
      if request.format.json?
        data = {
          token: user.authentication_token,
          email: user.email
        }
        render json: data, status: 201 and return
      end
    end
  end

  def sign_in_with_token
    user = SignInToken.authenticate(params[:token])

    if user.present?
      unless user.confirmed?
        ConfirmRegistration.call({ confirmation_token: user.confirmation_token, confirm_ip: request.remote_ip })
        user.reload
      end
      sign_in user
      render json: {
        email: user.email,
        token: user.authentication_token
      }, status: :created
    else
      render json: {
        error: 'Invalid or expired token'
      }, status: 422
    end
  end

  def oauth
    user_info = FacebookService.get_user_info(params[:accessToken])
    fb_user_info = ActiveSupport::HashWithIndifferentAccess.new(user_info)
    fb_user_info[:extra_info] = {}
    fb_user_info[:provider] = "facebook"
    fb_user_info[:extra_info][:verified] = fb_user_info[:verified]
    fb_user_info[:extra_info][:age_range] = fb_user_info[:age_range]
    fb_user_info[:extra_info][:time_zone] = fb_user_info[:timezone]
    fb_user_info[:extra_info][:gender] = fb_user_info[:gender]

    registration_attrs = {
      location: Location.find_by_slug_or_id(params[:location_id])
    }

    user = User.from_facebook_oauth(fb_user_info, registration_attrs)

    if user.present? && user.persisted?
      sign_in user
      render json: { email: user.email, token: user.authentication_token }, status: :created
    else
      missing_fields = user.errors.keys.map(&:to_s).join(",")
      render json: { error: "There was a problem signing in", missing_fields: missing_fields }, status: 422
    end
  end
end
