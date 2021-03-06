# frozen_string_literal: true

module Api
  module V3
    class Metrics::ProfilesController < ApiController
      before_action :confirm_content_published

      def create
        metric = ProfileMetric.create(profile_metric_params)
        if metric.persisted?
          render json: {}, status: 201
        else
          render json: { errors: metric.errors.full_messages }, status: 422
        end
      end

      private

      def profile_metric_params
        organization = Organization.find params[:id]

        {
          user_id: current_user.try(:id),
          user_agent: request.user_agent,
          user_ip: request.remote_ip,
          client_id: params[:client_id],
          content_id: params[:content_id],
          event_type: params[:event_type],
          organization: organization
        }.tap do |data|
          if params[:location_id].present?
            location = Location.find_by_slug_or_id(params[:location_id])
            data[:location_id] = location.try(:id)
            data[:location_confirmed] = ['1', 1, 'true', true].include?(params[:location_confirmed])
          end
        end
      end

      # catch non-published content before logging the profile_metric
      def confirm_content_published
        if params[:content_id].present?
          content = Content.find(params[:content_id])
          if content.pubdate.blank? || content.pubdate > Time.current
            render(json: {}, status: 200) && return
          end
        end
      end
    end
  end
end
