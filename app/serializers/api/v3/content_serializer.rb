module Api
  module V3
    class ContentSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :author_id, :author_name, :content_type,
        :publication_id, :publication_name, :venue_name, :venue_address,
        :published_at, :starts_at, :ends_at, :content

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      # we don't have this field yet. Returning authoremail for now
      def author_id
        object.authoremail
      end

      def author_name
        object.authors
      end

      def content_type
        object.root_content_category.name
      end

      def publication_name
        object.publication.name
      end

      def venue_name
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:name)
        end
      end

      def venue_address
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:address)
        end
      end

      def starts_at
        if object.channel_type == 'Event'
          object.channel.event_instances.first.try(:start_date)
        end
      end

      def ends_at
        if object.channel_type == 'Event'
          object.channel.event_instances.first.try(:end_date)
        end
      end

      def published_at
        object.pubdate
      end

      def content
        object.sanitized_content
      end

    end
  end
end