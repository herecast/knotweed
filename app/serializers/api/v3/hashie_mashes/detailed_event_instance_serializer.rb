module Api
  module V3
    module HashieMashes
      class DetailedEventInstanceSerializer < HashieMashSerializer
        attributes :id, :title, :subtitle, :starts_at, :ends_at, :image_url,
          :venue_name, :venue_address, :venue_city, :venue_state, :venue_url,
          :venue_longitude, :venue_latitude, :venue_locate_name,
          :venue_zip, :presenter_name, :registration_deadline, :cost_type,
          :created_at, :updated_at, :image_width, :image_height, :image_file_extension,
          :author_id, :author_name, :avatar_url, :organization_id, :organization_name, :organization_profile_image_url, :organization_biz_feed_active, :published_at, 
          :content,
          :content_id, :comment_count, :cost, :contact_email, :contact_phone, :updated_at, :event_id, :ical_url, :can_edit, :event_url

        attributes :comments, :event_instances, :content_locations

        def event_url
          object[:event_url]
        end

        def ical_url
          context[:ical_url] if context.present?
        end

        def image_url
          object[:image_url]
        end

        def can_edit
          if context.present? && context[:current_ability].present?
            context[:current_ability].can?(:manage, object)
          else
            false
          end
        end
      end
    end
  end
end
