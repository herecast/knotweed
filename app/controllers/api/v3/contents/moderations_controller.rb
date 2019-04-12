module Api
  module V3
    class Contents::ModerationsController < ApiController
      before_action :check_logged_in!

      def create
        @content = Content.find(params[:content_id])
        send_moderation_message
        render json: {}, status: :created
      end

      private

        def send_moderation_message
          ModerationMailer.send_moderation_flag_v2(
            @content,
            params[:flag_type],
            current_user
          ).deliver_later
        end

    end
  end
end