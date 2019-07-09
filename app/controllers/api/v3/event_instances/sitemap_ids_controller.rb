module Api
  module V3
    class EventInstances::SitemapIdsController < ApiController

      def index
        content_scope = Content.not_deleted
                               .not_removed
                               .where('pubdate <= ?', Time.zone.now)
        data = EventInstance.joins(event: :content)
                            .merge(content_scope)
                            .order('start_date DESC')
                            .limit(50_000)
                            .pluck(:id, 'contents.id')

        render json: {
          instances: data.map do |instance_pair|
            {
              id: instance_pair[0],
              content_id: instance_pair[1]
            }
          end
        }
      end
    end
  end
end