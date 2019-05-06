# frozen_string_literal: true

module Api
  module V3
    class MailchimpWebhooksController < ApiController
      def index
        render json: {}, status: :ok
      end

      def create
        MailchimpService::Webhooks.handle(params)
        render json: {}, status: :ok
      end
    end
  end
end
