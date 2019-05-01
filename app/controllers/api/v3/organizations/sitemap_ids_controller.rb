module Api
  module V3
    class Organizations::SitemapIdsController < ApiController

      def index
        ids = Organization.where("
                 (org_type IN (:publishers) AND can_publish_news = TRUE) OR
                 (org_type = 'Business' AND biz_feed_active = TRUE)
          ", publishers: %w[Blog Publisher Publication])\
                          .order('updated_at DESC')\
                          .limit(50_000)\
                          .pluck(:id)
        render json: {
          organization_ids: ids
        }
      end
    end
  end
end