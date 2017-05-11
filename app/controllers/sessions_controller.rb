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
end
