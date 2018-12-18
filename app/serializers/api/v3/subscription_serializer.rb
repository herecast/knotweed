# frozen_string_literal: true

module Api
  module V3
    class SubscriptionSerializer < ActiveModel::Serializer
      attributes :id, :email, :name, :user_id, :listserv_id, :created_at,
                 :confirmed_at, :unsubscribed_at, :email_type

      def id
        object.key
      end
    end
  end
end
