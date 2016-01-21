module Api
  module V3
    class NewsController < ApiController
      after_filter :track_index, only: :index
      after_filter :track_show, only: :show

      def index
        opts = { select: '*, weight()' }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:with][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :organization, :root_content_category] }
        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:with].merge!({org_id: allowed_orgs.collect{|c| c.id} })
        end

        if params[:location_id].present?
          opts[:with][:all_loc_ids] = params[:location_id].to_i
        end

        opts[:with][:root_content_category_id] = ContentCategory.find_by_name('news').id

        if params[:organization].present?
          org = Organization.find_by_name params[:organization]
          opts[:with][:org_id] = org.id if org.present?
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
        
        if @requesting_app.present?
          head :no_content and return unless @requesting_app.organizations.include?(@news.organization)
        end

        if @current_api_user.present?
          url = edit_content_url(@news) if @current_api_user.has_role? :admin
        else
          url = nil
        end

        if @news.try(:root_content_category).try(:name) != 'news'
          head :no_content
        else
          @news.increment_integer_attr!(:view_count)
          render json: @news, serializer: DetailedNewsSerializer, 
            admin_content_url: url, root: 'news'
        end
      end

      private 

      def track_index
        props = {}
        props.merge! @tracker.navigation_properties('News','news.index', url_for, params)
        props.merge! @tracker.search_properties(params)
        @tracker.track(@mixpanel_distinct_id, 'searchContent', @current_api_user, props)
      end

      def track_show
        props = {}
        props.merge! @tracker.navigation_properties('News','news.index', url_for, params)
        props.merge! @tracker.content_properties(@news)
        @tracker.track(@mixpanel_distinct_id, 'selectContent', @current_api_user, props)
      end

    end
  end
end
