module SearchIndexing
  class ContentSerializer < ::Api::V3::ContentSerializer
    attributes :channel_id,
               :channel_type,
               :content_category_id,
               :content_category_name,
               :created_by_id,
               :created_by_image_url,
               :created_by_name,
               :deleted,
               :in_accepted_category,
               :latest_activity,
               :origin,
               :parent_id,
               :pubdate,
               :removed,
               :root_content_category_id,
               :root_parent_id,
               :has_future_event_instance,
               :organization_order_moment

    has_many :comments, serializer: SearchIndexing::CommentSerializer

    def comments
      object.children.to_a.select { |c| !c[:pubdate].nil? && c[:deleted_at].nil? }.sort_by(&:pubdate).reverse.take(6)
    end

    def content_category_name
      object.content_category.try(:name)
    end

    def deleted
      object.deleted_at.present?
    end

    def in_accepted_category
      !(object.content_category.try(:name) == 'event' and object.channel_type != 'Event')
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

    # do not include split content in index
    def filter keys
      keys - [:split_content]
    end

    def organization_order_moment
      object.content_type == :event ? object.latest_activity : object.pubdate
    end
  end
end
