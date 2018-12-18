# frozen_string_literal: true

module Api
  module V3
    module HashieMashes
      class DetailedEventInstanceSerializer < HashieMashSerializer
        attributes :id,
                   :author_id,
                   :author_name,
                   :avatar_url,
                   :biz_feed_public,
                   :comments,
                   :comment_count,
                   :commenter_count,
                   :contact_email,
                   :contact_phone,
                   :content,
                   :content_id,
                   :content_origin,
                   :cost,
                   :cost_type,
                   :created_at,
                   :ends_at,
                   :event_id,
                   :event_instances,
                   :event_url,
                   :ical_url,
                   :images,
                   :image_url,
                   :location_id,
                   :organization_biz_feed_active,
                   :organization_id,
                   :organization_name,
                   :organization_profile_image_url,
                   :presenter_name,
                   :promote_radius,
                   :published_at,
                   :registration_deadline,
                   :starts_at,
                   :subtitle,
                   :title,
                   :updated_at,
                   :venue_address,
                   :venue_city,
                   :venue_latitude,
                   :venue_longitude,
                   :venue_name,
                   :venue_state,
                   :venue_url,
                   :venue_zip

        def event_url
          object[:event_url]
        end

        def ical_url
          context[:ical_url] if context.present?
        end

        def image_url
          object[:image_url]
        end
      end
    end
  end
end
