# frozen_string_literal: true

###
# This serializer will be operating on the elasticsearch document,
# which is likely different than the actual content record.  So be
# careful to not assume the whole content object graph exists here.
#

module Api
  module V3
    module HashieMashes
      class ContentSerializer < HashieMashSerializer
        attributes :id,
                   :author_id,
                   :author_name,
                   :avatar_url,
                   :biz_feed_public,
                   :campaign_end,
                   :campaign_start,
                   :click_count,
                   :comments,
                   :comment_count,
                   :commenter_count,
                   :contact_email,
                   :contact_phone,
                   :content,
                   :content_origin,
                   :content_type,
                   :cost,
                   :cost_type,
                   :created_at,
                   :embedded_ad,
                   :ends_at,
                   :event_url,
                   :event_instance_id,
                   :event_instances,
                   :images,
                   :image_url,
                   :like_count,
                   :location,
                   :location_id,
                   :organization,
                   :organization_id,
                   :organization_name,
                   :parent_content_id,
                   :parent_content_type,
                   :parent_event_instance_id,
                   :promote_radius,
                   :published_at,
                   :redirect_url,
                   :registration_deadline,
                   :schedules,
                   :short_link,
                   :sold,
                   :starts_at,
                   :subtitle,
                   :sunset_date,
                   :title,
                   :updated_at,
                   :url,
                   :user_id,
                   :user_image_url,
                   :user_name,
                   :venue_id,
                   :venue_address,
                   :venue_city,
                   :venue_name,
                   :venue_state,
                   :venue_url,
                   :venue_zip,
                   :view_count

        def event_instance_id
          next_or_first_instance.try(:id) if is_event?
        end

        # do not delete. It gets confused with url helper methods.
        def image_url
          object.image_url
        end

        def event_url
          object.event_url
        end

        def images
          object.images
        end

        def next_or_first_instance
          instances_by_start_date = (object.event_instances || []).sort_by do |inst|
            DateTime.parse(inst.starts_at)
          end
          instances_by_start_date.find do |instance|
            DateTime.parse(instance.starts_at) >= Time.zone.now
          end || instances_by_start_date.first
        end

        def starts_at
          next_or_first_instance.try(:starts_at) if is_event?
        end

        def ends_at
          next_or_first_instance.try(:ends_at) if is_event?
        end

        def content
          if object.content.try(:match, /No content found/)
            ''
          else
            object.content
          end
        end

        def user_id
          object.created_by_id
        end

        def user_image_url
          object.created_by_image_url
        end

        def user_name
          object.created_by_name
        end

        def view_count
          Content.find_by(id: object.id)&.built_view_count
        end

        private

        def is_event?
          object.content_type.to_s == 'event'
        end
      end
    end
  end
end
