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

      def user_id
        if object.user_id.nil? && object.has_account?
          object.user_account_id
        else
          object.user_id
        end
      end

      def body
        if object.body.eql? "No content found"
          String.new("")
        else
          object.body
        end
      end
    end
  end
end
