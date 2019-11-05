module Api
  module V3
    class ModerationsController < ApiController
      before_action :check_logged_in!

      def create
        if params[:content_type] == 'comment'
          @subject = Comment.find(params[:id])
        elsif params[:content_type] == 'content'
          @subject = Content.find(params[:id])
        end
        if @subject.present?
          send_moderation_message
          render json: {}, status: :created
        else
          render json: {}, status: :not_found
        end
      end

      private

        def send_moderation_message
          ModerationMailer.send_moderation_flag_v2(
            @subject,
            params[:flag_type],
            current_user
          ).deliver_later
        end

    end
  end
end
