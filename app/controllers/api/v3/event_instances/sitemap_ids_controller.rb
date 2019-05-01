module Api
  module V3
    class EventInstances::SitemapIdsController < ApiController

      def index
        data = EventInstance.joins(event: :content).merge(
          Content
          .not_deleted
          .not_removed
          .where('pubdate <= ?', Time.zone.now)
        ).order('start_date DESC')\
                            .limit(50_000)\
                            .select('event_instances.id as id, contents.id as content_id')

        render json: {
          instances: data.map do |instance|
            {
              id: instance.id,
              content_id: instance.content_id
            }
          end
        }
      end
    end
  end
end