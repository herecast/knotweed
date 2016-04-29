module Api
  module V3
    class PasswordsController < Devise::PasswordsController

      before_filter :set_consumer_app_in_thread

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
           render json: {}, status: 200
         else
           render json: { errors: resource.errors.full_messages }, status: 404
         end
       end

       private

       def set_consumer_app_in_thread
         if request.headers['Consumer-App-Uri'].present?
           ConsumerApp.current = ConsumerApp.find_by_uri(request.headers['Consumer-App-Uri'])
         end
       end
     
    end
  end
end
