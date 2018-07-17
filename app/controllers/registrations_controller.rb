class RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_filter :set_consumer_app_in_thread

  def create
    super do |user|
      if request.format.json?
        if params[:instant_signup] == true
          user.location_id = Location::REGION_LOCATION_ID
          user.confirmed_at = Time.current
          user.nda_agreed_at = Time.current
          user.agreed_to_nda = true
          if user.save
            user.ensure_authentication_token
            render json: payload(user), status: :created and return
          else
            render json: { errors: user.errors }, status: 422 and return
          end
        else
          res = {
            :message => "Thank you! For security purposes, a message with a confirmation link has been sent to your email address. Please check your email and click on the link to activate your account. If the message hasn't appeared in a few minutes, please check your spam folder."
          }
          user.nda_agreed_at = Time.zone.now
          user.agreed_to_nda = true

          if user.save
            render json: res, status: 201 and return
          else
            render json: {errors: user.errors}, status: 422 and return
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
    params.require(:user).permit(:name, :email, :location_id, :password, :password_confirmation,
                                :current_password)
  end

   def set_consumer_app_in_thread
     if request.headers['Consumer-App-Uri'].present?
       ConsumerApp.current = ConsumerApp.find_by_uri(request.headers['Consumer-App-Uri'])
     end
   end
end
