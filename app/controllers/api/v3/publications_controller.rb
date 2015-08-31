module Api
  module V3
    class PublicationsController < ApiController

      def index
        opts = {}
        opts = { select: '*, weight()' }
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:star] = true

        if @requesting_app.present?
          opts[:with][:consumer_app_ids] = @requesting_app.id
        end

        # only use publications associated with news content
        news_cat = ContentCategory.find_by_name 'news'
        opts[:with][:content_category_ids] = news_cat.id

        query = Riddle::Query.escape("#{params[:query]}")
        
        @publications = Publication.search query, opts

        render json: @publications, each_serializer: PublicationSerializer
      end

    end
  end
end
