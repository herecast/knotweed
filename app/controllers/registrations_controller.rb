class RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json

  def create 
    super do |user|
      if request.format.json?
        res = {
          token: user.authentication_token,
          email: user.email
        }
        # temporary solution to support running UX1 and UX2 simultaneously
        # can be removed when we moonlight UX1!
        user.nda_agreed_at = Time.zone.now
        user.agreed_to_nda = true
        user.save
        render json: res, status: 201 and return
      end
    end
  end

end
