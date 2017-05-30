module Api
  module V3
    class Metrics::Contents::ImpressionsController < ApiController

      def create
        content = Content.not_deleted.find params[:id]

        unless analytics_blocked?
          if content.content_type == :news
            BackgroundJob.perform_later("RecordContentMetric", "call",
              content,
              'impression',
              Date.current.to_s, {
                user_id:    @current_api_user.try(:id),
                user_agent: request.user_agent,
                user_ip:    request.remote_ip,
                client_id: params[:client_id]
              }
            )
          else
            content.increment!(:view_count)
          end

          if @repository.present?
            if params[:client_id] || user_signed_in?
              BackgroundJob.perform_later("DspService", "record_user_visit",
                content,
                @current_api_user.try(:email) || params[:client_id],
                @repository
              ) unless analytics_blocked?
            end
          end
        end

        render json: {}, status: :accepted
      end
    end
  end
end
