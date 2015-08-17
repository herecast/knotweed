module Api
  module V3
    class SimilarContentSerializer < ActiveModel::Serializer

      attributes :content_id, :title, :author, :pubdate, :content,
        :event_instance_id, :content_url

      def content
        object.sanitized_content
      end

      def content_id
        object.id
      end

      def author
        object.authors
      end

      def event_instance_id
        if object.channel_type == 'Event'
          object.channel.event_instances.first.id
        end
      end

      def content_url
        if serialization_options.has_key? :consumer_app_base_uri and object.channel_type != 'Event'
          serialization_options[:consumer_app_base_uri] + "/contents/#{object.id}" if serialization_options[:consumer_app_base_uri].present?
        end
      end

    end
  end
end
