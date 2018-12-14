module Api
  module V3
    class PasswordsController < Devise::PasswordsController
      respond_to :json

      # POST /resource/password
      def create
        self.resource = resource_class.send_reset_password_instructions(resource_params)
        yield resource if block_given?

        if successfully_sent?(resource)
          render json: {
            message: "We've sent an email to #{resource.email} containing a temporary link that will allow you to reset your password"
          }
        else
          respond_with(resource)
        end
      end

      # PUT /resource/password
      def update
        self.resource = resource_class.reset_password_by_token(resource_params)
        yield resource if block_given?

        if resource.errors.empty?
          resource.unlock_access! if unlockable?(resource)
          head :no_content
        else
          render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def resource_params
        super.merge({
                      return_url: params[:return_url]
                    })
      end
    end
  end
end
