module Api
  module V3
    class Contents::SitemapIdsController < ApiController

      def index
        types = (params[:type] || 'news,market,talk').split(/,\s*/).map do |type|
          if type == 'talk'
            'talk_of_the_town'
          else
            type
          end
        end

        content_ids = Content.not_deleted
                             .not_removed
                             .where('pubdate <= ?', Time.zone.now)
                             .only_categories(types)
                             .order('pubdate DESC')
                             .limit(50_000)
                             .pluck(:id)

        render json: { content_ids: content_ids }
      end
    end
  end
end
