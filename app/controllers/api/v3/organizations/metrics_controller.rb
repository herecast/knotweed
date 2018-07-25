module Api
  module V3
    class Organizations::MetricsController < ApiController
      def index
        @organization = Organization.find(params[:organization_id])
        authorize! :manage, @organization
        if params[:start_date].present? && params[:end_date].present?
          render json: @organization, serializer: OrganizationMetricsSerializer,
            context: {
              start_date: Date.parse(params[:start_date]),
              end_date: Date.parse(params[:end_date])
            },
            root: :content_metrics
        else
          render json: {}, status: :bad_request
        end
      end
    end
  end
end
