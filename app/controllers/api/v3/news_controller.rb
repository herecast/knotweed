module Api
  module V3
    class NewsController < ApiController

      def index
        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:conditions][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :publication, :root_content_category] }
        if @requesting_app.present?
          allowed_pubs = @requesting_app.publications
          opts[:with].merge!({pub_id: allowed_pubs.collect{|c| c.id} })
        end

        if params[:location_id].present?
          location_condition = params[:location_id].to_i
        else
          location_condition = Location.find_by_city(Location::DEFAULT_LOCATION).id
        end

        root_news_cat = ContentCategory.find_by_name 'news'

        opts[:with].merge!({
          all_loc_ids: [location_condition], 
          root_content_category_id: root_news_cat.id
        })

        if params[:publication].present?
          pub = Publication.find_by_name params[:publication]
          opts[:with][:pub_id] = pub.id if pub.present?
        end
        
        if params[:query].present?
          query = Riddle::Query.escape(params[:query]) 
        else
          query = ''
        end
        @news = Content.search query, opts
        render json: @news, each_serializer: NewsSerializer
      end

      def show
        @news = Content.find params[:id]
        
        if @current_api_user.present?
          url = edit_content_url(@news) if @current_api_user.has_role? :admin
        else
          url = nil
        end

        if @news.try(:root_content_category).try(:name) != 'news'
          head :no_content
        else
          render json: @news, serializer: DetailedNewsSerializer, 
            admin_content_url: url, root: 'news'
        end
      end

    end
  end
end
