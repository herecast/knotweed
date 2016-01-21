module Api
  module V3
    class OrganizationsController < ApiController

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

        # only use organizations associated with news content
        news_cat = ContentCategory.find_by_name 'news'
        opts[:with][:content_category_ids] = news_cat.id

        query = Riddle::Query.escape("#{params[:query]}")
        
        @organizations = Organization.search query, opts

        render json: @organizations, each_serializer: OrganizationSerializer
      end

    end
  end
end
