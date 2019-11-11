# frozen_string_literal: true

module SearchIndexing
  class ContentSerializer < ::Api::V3::ContentSerializer
    attributes :channel_id,
               :channel_type,
               :content_category_name,
               :created_by_id,
               :created_by_image_url,
               :created_by_name,
               :in_accepted_category,
               :latest_activity,
               :origin,
               :parent_id,
               :pubdate,
               :removed,
               :root_parent_id,
               :has_future_event_instance,
               :organization_order_moment,
               :commented_on_by_ids

    has_many :comments, serializer: Api::V3::CommentSerializer

    def comments
      object.available_comments
    end

    # user IDs who have commented on this content
    def commented_on_by_ids
      object.available_comments.map(&:created_by_id)
    end

    def content_category_name
      object.content_category
    end

    def in_accepted_category
      !((object.content_category == 'event') && (object.channel_type != 'Event'))
    end

    def created_by_id
      object.created_by_id
    end

    def created_by_image_url
      object.created_by.try(:avatar_url)
    end

    def created_by_name
      object.created_by.try(:name)
    end

    def organization_order_moment
      object.content_type == 'event' ? object.latest_activity : object.pubdate
    end
  end
end
