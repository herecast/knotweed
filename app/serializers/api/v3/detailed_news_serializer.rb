module Api
  module V3
    class DetailedNewsSerializer < ActiveModel::Serializer

      attributes :id, :content_id, :admin_content_url, :content, :title, :subtitle,
        :author_name, :author_id, :organization_name, :organization_id, :published_at, :comment_count,
        :is_sponsored_content, :created_at, :updated_at, :can_edit, :split_content

      has_many :images

      def content_id
        object.id
      end

      def admin_content_url
        serialization_options[:admin_content_url]
      end

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

      def author_id
        object.created_by.try(:id)
      end

      def published_at
        object.pubdate
      end

      def comment_count
        object.comment_count
      end

      def is_sponsored_content
        object.is_sponsored_content?
      end

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:manage, object)
        else
          false
        end
      end

      def split_content
        # Images in the news detail will appear in a 600px wide rectangle with no height
        # restriction.  We don't want to crop (no need to, given arbitrary height of the detail
        # modal), so we do a fit instead of a crop.  each image does need to fit into a 600-wide rectangle,
        # however, and for the height, we arbitrarily choose a max height of three times that width.
        # We chould make the default height bigger than that if we need to, but 3x should be fine.

        object.split_content.tap { |head_and_tail|
          head_and_tail[:head] = ImageUrlService.optimize_image_urls(html_text:      head_and_tail[:head],
                                                                     default_width:  600,
                                                                     default_height: 1800,
                                                                     default_crop:   false)

          head_and_tail[:tail] = ImageUrlService.optimize_image_urls(html_text:      head_and_tail[:tail],
                                                                     default_width:  600,
                                                                     default_height: 1800,
                                                                     default_crop:   false)
        }
      end
    end
  end
end
