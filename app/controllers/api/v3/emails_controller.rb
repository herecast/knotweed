module Api
  module V3
    class EmailsController < ApiController

      def create
        received_email = ReceivedEmail.new(
          file_uri: params[:file_uri]
        )

        if received_email.save
          ProcessReceivedEmailJob.perform_later(received_email)
          head :accepted
        else
          render text: received_email.errors.full_messages.join('\n'), status: 422
        end
      end

    end
  end
end
