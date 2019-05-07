# frozen_string_literal: true

module Api
  module V3
    class Users::ConfirmationsController < ApiController

      # email_confirmation
      def create
        user = ConfirmRegistration.call(confirmation_token: params[:confirmation_token],
                                        confirm_ip: request.remote_ip)
        if user.errors.blank?
          resp = { token: user.authentication_token,
                   email: user.email }
          render json: resp
        else
          head :not_found
        end
      end

      # resend_confirmation
      # NOTE -- this is a POST request not a PUT request because of status quo,
      # but could be converted to a PUT request with corresponding Ember change
      def update
        user = User.find_by_email(params[:user][:email])
        if user.present?
          if user.confirmed?
            render json: { message: 'User already confirmed.' }, status: 200
          else
            user.resend_confirmation_instructions
            render json: { message: "We've sent an email to #{params[:user][:email]} containing a confirmation link" },
                   status: 200
          end
        else
          render json: { errors: "#{params[:user][:email]} not found" }, status: 404
        end
      end

    end
  end
end
