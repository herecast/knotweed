module SearchIndexing
  class ContentSerializer < ::Api::V3::ContentSerializer
    attributes :all_loc_ids,
      :about_location_ids,
      :base_location_ids,
      :channel_id,
      :channel_type,
      :content_category_id,
      :content_category_name,
      :created_by_id,
      :deleted,
      :in_accepted_category,
      :is_listserv_market_post,
      :latest_activity,
      :my_town_only,
      :origin,
      :parent_id,
      :pubdate,
      :published,
      :removed,
      :root_content_category_id,
      :root_parent_id

    has_many :comments, serializer: SearchIndexing::CommentSerializer

    def comments
      object.children.to_a.select(&:pubdate).sort_by(&:pubdate).reverse.take(6)
    end

    def content_category_name
      object.content_category.try(:name)
    end

    def base_location_ids
      if object.association(:content_locations).loaded?
        base_ids = object.content_locations.select(&:base?).map(&:location_id)
      else
        base_ids = object.base_locations.map(&:id)
      end

      if object.organization.present?
        base_ids |= object.organization.base_locations.map(&:id)
      end

      base_ids.uniq
    end

    def about_location_ids
      if object.association(:content_locations).loaded?
        about_ids = object.content_locations.select(&:about?).map(&:location_id)
      else
        about_ids = object.about_locations.map(&:id)
      end
      about_ids.uniq
    end

    def is_listserv_market_post
      object.is_listserv_market_post?
    end

    def deleted
      object.deleted_at.present?
    end

    def in_accepted_category
      !(object.content_category.try(:name) == 'event' and object.channel_type != 'Event')
    end

    def created_by_id
      object.created_by.try(:id)
    end

    # do not include split content in index
    def filter keys
      keys - [:split_content]
    end

  end
end
