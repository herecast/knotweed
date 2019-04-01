module Api
  module V3
    class Organizations::EmailCapturesController < ApiController

      def create
        send_slack_notification
        subscribe_email_to_mobile_blogger_interest_list
        render json: {}, status: :ok
      end

      private

        def send_slack_notification
          if Figaro.env.production_messaging_enabled == 'true'
            SlackService.send_new_blogger_email_capture(params[:email])
          end
        end

        def subscribe_email_to_mobile_blogger_interest_list
          BackgroundJob.perform_later(
            "Outreach::AddEmailToMobileBloggerInterestList",
            "call",
            params[:email]
          )
        end

    end
  end
end