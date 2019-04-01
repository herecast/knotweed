# frozen_string_literal: true

module Api
  module V3
    class MailchimpWebhooksController < ApiController
      def index
        render json: {}, status: :ok
      end

      def create
        Outreach::DestroyUserOrganizationSubscriptions.call(params)
        render json: {}, status: :ok
      end
    end
  end
end
