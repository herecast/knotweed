module Api
  module V3
    class Contents::NotificationsController < ApiController

      def create
        @content = Content.find(params[:content_id])
        authorize! :update, @content
        if @content.mc_campaign_id.nil?
          schedule_email_notification
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

        def schedule_email_notification
          BackgroundJob.perform_later('Outreach::SendOrganizationPostNotification',
            'call',
            @content
          )
        end

    end
  end
end