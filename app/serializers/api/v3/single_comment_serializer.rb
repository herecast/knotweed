# frozen_string_literal: true

module Api
  module V3
    class SingleCommentSerializer < ActiveModel::Serializer
      attributes :id, :content, :parent_comment_id, :user_name,
                 :event_instance_id, :pubdate

      def id
        object.channel.id
      end

      def content
        object.sanitized_content
      end

      def parent_comment_id
        if object.parent.present? && object.parent.channel.is_a?(Comment)
          object.parent.channel.id
        end
      end

      def user_name
        object.authors
      end

      def event_instance_id
        if object.parent.present? && object.parent.channel.is_a?(Event)
          object.parent.channel.event_instances.first.id
        end
      end
    end
  end
end
