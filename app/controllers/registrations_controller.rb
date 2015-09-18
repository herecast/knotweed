class RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json

  def create 
    super do |user|
      if request.format.json?
        res = {
          token: user.authentication_token,
          email: user.email
        }
        render json: res, status: 201 and return
      end
    end
  end

end
