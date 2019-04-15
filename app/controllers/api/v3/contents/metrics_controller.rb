module Api
  module V3
    class Contents::MetricsController < ApiController
      before_action :check_logged_in!

      def index
        @content = Content.find(params[:content_id])
        authorize! :manage, @content
        if params[:start_date].present? && params[:end_date].present?
          render json: @content, serializer: ContentMetricsSerializer,
                 context: { start_date: params[:start_date], end_date: params[:end_date] }
        else
          render json: {}, status: :bad_request
        end
      end
    end
  end
end