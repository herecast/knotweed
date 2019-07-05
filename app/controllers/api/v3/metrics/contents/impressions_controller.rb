# frozen_string_literal: true

module Api
  module V3
    class Metrics::Contents::ImpressionsController < ApiController
      def create
        @content = Content.not_deleted.find params[:id]

        unless analytics_blocked?
          RecordContentMetric.call(@content, content_metric_params)
        end

        render json: {}, status: :accepted
      end

      private

      def content_metric_params
        data = {
          event_type: 'impression',
          current_date: Date.current.to_s,
          user_id: current_user.try(:id),
          user_agent: request.user_agent,
          user_ip: request.remote_ip,
          client_id: params[:client_id]
        }

        if params[:location_id].present?
          location = Location.find_by_slug_or_id(params[:location_id])
          data[:location_id] = location.try(:id)
          data[:location_confirmed] = ['1', 1, 'true', true].include?(params[:location_confirmed])
        end

        data
      end
    end
  end
end
