###
# This serializer will be operating on the elasticsearch document,
# which is likely different than the actual content record.  So be
# careful to not assume the whole content object graph exists here.
#

module Api
  module V3
    module HashieMashes
      class FeedContentSerializer < HashieMashSerializer
        attributes :id, :title, :image_url, :author_id, :author_name, :content_type,
          :organization_id, :organization_name, :subtitle, :venue_zip,
          :published_at, :starts_at, :ends_at, :content, :view_count, :commenter_count,
          :comment_count, :parent_content_id, :content_id, :parent_content_type,
          :event_instance_id, :parent_event_instance_id, :registration_deadline,
          :created_at, :updated_at, :event_id, :cost, :sold, :avatar_url,
          :organization_profile_image_url, :biz_feed_public, :sunset_date,
          :event_instances, :content_origin, :split_content, :cost_type, :contact_phone,
          :images, :can_edit, :contact_email, :venue_url, :organization_biz_feed_active,
          :campaign_start, :campaign_end

        has_many :content_locations, serializer: Api::V3::HashieMashes::ContentLocationSerializer
        has_many :comments, serializer: Api::V3::HashieMashes::CommentSerializer

        def content_id
          object.id
        end

        def event_instance_id
          if is_event?
            next_or_first_instance.try(:id)
          end
        end

        def image_url
          if object.images.present?
            object.images[0].image_url
          end
        end

        def images
          object.images.sort_by{|i| [i.position, i.created_at]}.map do |img|
            {
              id: img.id,
              image_url: img.image_url,
              primary: img.primary ? 1 : 0,
              width: img.width,
              height: img.height,
              file_extension: img.file_extension,
              caption: img.caption
            }
          end
        end

        def author_id
          object.created_by.try(:id)
        end

        def venue_name
          if is_event?
            object.venue.try(:name)
          end
        end

        def venue_city
          if is_event?
            object.venue.try(:city)
          end
        end

        def venue_state
          if is_event?
            object.venue.try(:state)
          end
        end

        def venue_zip
          if is_event? && object.venue.present?
            # avoid using ruby's zip method
            object.venue[:zip]
          end
        end

        def venue_url
          if is_event?
            object.venue.try(:venue_url)
          end
        end

        def venue_address
          if is_event?
            object.venue.try(:address)
          end
        end

        def next_or_first_instance
          instances_by_start_date = object.event_instances.sort_by(&:start_date)
          instances_by_start_date.find do |instance|
            instance.start_date >= Time.zone.now
          end || instances_by_start_date.first
        end

        def starts_at
          if is_event?
            next_or_first_instance.try(:start_date)
          end
        end

        def ends_at
          if is_event?
            next_or_first_instance.try(:end_date)
          end
        end

        def published_at
          object.pubdate
        end

        def content
          if object.content.match(/No content found/)
            ""
          else
            object.content
          end
        end

        def view_count
          if object.parent_id
            object.parent_view_count
          else
            object.view_count
          end
        end

        def commenter_count
          if object.parent_id
            object.parent_commenter_count
          else
            object.commenter_count
          end
        end

        def comment_count
          if object.parent_id
            object.parent_comment_count
          else
            object.comment_count
          end
        end

        def parent_content_id
          object.parent_id
        end

        def parent_event_instance_id
          if object.parent.present? and object.parent.channel_type == 'Event'
            object.parent.channel.event_instances.first.id
          end
        end

        def registration_deadline
          if is_event?
            object.try(:registration_deadline)
          end
        end

        def filter(keys)

          if is_event?
            return keys | %w(
              event_instance_id venue_name venue_address
              venue_city venue_state parent_event_instance_id
              registration_deadline
            )
          end

          keys
        end

        def event_id
          if is_event?
            object.channel_id
          end
        end

        def cost
          object.try(:cost)
        end

        def sold
          if is_market?
            object.sold
          end
        end

        def avatar_url
          object.created_by.try(:avatar_url)
        end

        def organization_profile_image_url
          object.organization.try(:profile_image_url) || object.organization.try(:logo_url)
        end

        def organization_name
          object.organization.name
        end

        def can_edit
          if context.present? && context[:current_ability].present?
            context[:current_ability].can?(:manage, object)
          else
            false
          end
        end

        def base_location
          object.location
        end

        def content_origin
          object.organization.try(:name) == 'Listserv' ? 'listserv' : 'ugc'
        end

        def event_instances
          if is_event?
            object.event_instances.map do |inst|
              Api::V3::HashieMashes::EventInstanceSerializer.new(inst).serializable_hash
            end
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

        def cost_type
          if is_event?
            object.try(:cost_type)
          end
        end

        def contact_phone
          object.try(:contact_phone)
        end

        def contact_email
          object.try(:contact_email)
        end

        def organization_biz_feed_active
          !!object.organization.try(:biz_feed_active)
        end

        def campaign_start
          object.campaign_start
        end

        def campaign_end
          object.campaign_end
        end

        private

          def is_event?
            object.content_type.to_s == 'event'
          end

          def is_market?
            object.content_type.to_s == 'market'
          end

      end
    end
  end
end
