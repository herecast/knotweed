module Api
  module V3
    class ListservContentSerializer < ActiveModel::Serializer
      attributes :id, :listserv_id, :subscription_id, :user_id, :subject, :body,
        :sender_email, :sender_name, :channel_type, :verified_at, :content_id

      def id
        object.key
      end

      def subscription_id
        object.subscription.try(:key)
      end
    end
  end
end
