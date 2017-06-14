module Api
  module V3
    class ConfirmedRegistrationsController < ApiController
      before_action :validate_confirmation_record, only: [:create]

      def create
        user = User.new(user_params)

        unless user.password.present?
          create_temp_password(user)
        end

        user.confirmed_at = Time.zone.now

        user.location_id ||= default_location.id

        if user.save
          render status: 201, json:  {
            email: user.email,
            token: user.authentication_token
          }
        else
          render json: {errors: user.errors}, status: 422
        end
      end

      protected
      def registration_params
        params.require(:registration).permit(
          :email, :password, :location_id, :name, :confirmation_key
        )
      end

      def user_params
        registration_params.except(:confirmation_key)
      end

      def confirmation_key
        registration_params[:confirmation_key]
      end

      def confirmation_class
        klass = confirmation_key.split('/')[0].classify
        klass.constantize
      end

      def confirmation_id
        confirmation_key.split('/')[1]
      end

      def validate_confirmation_record
        @confirmation_record = confirmation_class.find(confirmation_id)
      rescue ActiveRecord::RecordNotFound, NameError
        render json: {errors: ['invalid confirmation_key']}, status: 422
      end

      def create_temp_password(user)
        pw = SecureRandom.hex(4)
        user.temp_password = AESCrypt.encrypt(pw, confirmation_key)
        user.password = pw
      end

      def default_location
        Location.find_or_create_by(
          city: "Lebanon",
          state: 'NH'
        )
      end
    end
  end
end
