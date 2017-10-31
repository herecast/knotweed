module SearchIndexing
  class ContentSerializer < ActiveModel::Serializer
    attributes :id, :title, :subtitle, :content, :author_name, :pubdate,
      :all_loc_ids, :base_location_ids, :about_location_ids, :origin,
      :published, :channel_type, :channel_id, :content_type,
      :root_content_category_id, :content_category_id, :my_town_only, :deleted,
      :root_parent_id, :in_accepted_category, :is_listserv_market_post,
      :organization_id, :organization_name, :created_at, :updated_at, :biz_feed_public,
      :campaign_start, :campaign_end

    attributes :view_count, :commenter_count, :comment_count, :parent_id,
      :parent_content_type, :sunset_date, :latest_activity

    has_many :images, serializer: SearchIndexing::ImageSerializer
    has_many :content_locations, serializer: SearchIndexing::ContentLocationSerializer
    has_many :comments, serializer: SearchIndexing::CommentSerializer

    has_one :created_by, serializer: SearchIndexing::CreatedBySerializer
    has_one :organization, serializer: SearchIndexing::OrganizationSerializer

    def comments
      object.children.to_a.select(&:pubdate).sort_by(&:pubdate).reverse.take(6)
    end

    def organization_name
      object.organization.try(:name)
    end

    def base_location_ids
      base_ids = object.base_locations.map(&:id)

      if object.organization.present?
         base_ids |= organization.base_locations.map(&:id)
      end

      base_ids
    end

    def about_location_ids
      object.about_locations.map(&:id)
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

    def content
      object.sanitized_content
    end

    def title
      object.sanitized_title
    end

    def commenter_count
      if object.parent.present?
        object.parent_commenter_count
      else
        object.commenter_count
      end
    end

    def comment_count
      if object.parent.present?
        object.parent_comment_count
      else
        object.comment_count
      end
    end

    def parent_content_id
      object.parent_id
    end

    def parent_content_type
      if object.parent.present? and object.parent.root_content_category.present?
        object.parent.root_content_category.name
      end
    end

    def view_count
      if object.parent.present?
        object.parent_view_count
      else
        object.view_count
      end
    end

    def campaign_start
      object.ad_campaign_start
    end

    def campaign_end
      object.ad_campaign_end
    end
  end
end
