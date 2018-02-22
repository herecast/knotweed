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
        :content_locations,
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
        :organization_biz_feed_active,
        :organization_id,
        :organization_name,
        :organization_profile_image_url,
        :parent_content_id,
        :parent_content_type,
        :parent_event_instance_id,
        :promote_radius,
        :published_at,
        :redirect_url,
        :registration_deadline,
        :schedules,
        :sold,
        :split_content,
        :starts_at,
        :subtitle,
        :sunset_date,
        :title,
        :ugc_base_location_id,
        :updated_at,
        :venue_address,
        :venue_city,
        :venue_name,
        :venue_state,
        :venue_url,
        :venue_zip,
        :view_count

        def event_instance_id
          if is_event?
            next_or_first_instance.try(:id)
          end
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
          instances_by_start_date = (object.event_instances || []).sort_by{|inst|
            DateTime.parse(inst.starts_at)
          }
          instances_by_start_date.find do |instance|
            DateTime.parse(instance.starts_at) >= Time.zone.now
          end || instances_by_start_date.first
        end

        def starts_at
          if is_event?
            next_or_first_instance.try(:starts_at)
          end
        end

        def ends_at
          if is_event?
            next_or_first_instance.try(:ends_at)
          end
        end

        def content
          if object.content.try(:match, /No content found/)
            ""
          else
            object.content
          end
        end

        def split_content
          SplitContentForAdPlacement.call(
            ImageUrlService.optimize_image_urls(
              html_text: content,
              default_width:  600,
              default_height: 1800,
              default_crop:   false
            )
          ).tap do |h|
            if h[:tail].nil?
              h[:tail] = ""
            end
          end
        end

        private

          def is_event?
            object.content_type.to_s == 'event'
          end

      end
    end
  end
end