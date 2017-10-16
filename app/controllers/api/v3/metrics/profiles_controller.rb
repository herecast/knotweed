module Api
  module V3
    class Metrics::ProfilesController < ApiController

      def impression
        metric = ProfileMetric.create(
          profile_metric_params.merge(
            event_type: 'impression'
          )
        )
        if metric.persisted?
          render json: {}, status: 201
        else
          render json: {errors: metric.errors.full_messages}, status: 422
        end
      end

      def click
        metric = ProfileMetric.create(
          profile_metric_params.merge(
            event_type: 'click'
          )
        )
        if metric.persisted?
          render json: {}, status: 201
        else
          render json: {errors: metric.errors.full_messages}, status: 422
        end
      end

      private
      def profile_metric_params
        organization = Organization.find params[:id]

        return {
          user_id:    @current_api_user.try(:id),
          user_agent: request.user_agent,
          user_ip:    request.remote_ip,
          client_id: params[:client_id],
          content_id: params[:content_id],
          organization: organization
        }.tap do |data|
          if params[:location_id].present?
            location = Location.find_by_slug_or_id(params[:location_id])
            data[:location_id] = location.try(:id)
            data[:location_confirmed] = [1, 'true'].include?(params[:location_confirmed])
          end
        end
      end
    end
  end
end
