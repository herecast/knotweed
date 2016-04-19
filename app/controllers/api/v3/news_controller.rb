module Api
  module V3
    class NewsController < ApiController
      before_filter :check_logged_in!, :parse_params!, only: [:create, :update]

      def create
        news_cat = ContentCategory.find_or_create_by(name: 'news')
        @news = Content.new(params[:news].merge(content_category_id: news_cat.id))
        if @news.save
          if @repository.present? and @news.pubdate.present? # don't publish drafts
            @news.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end

          render json: @news, serializer: DetailedNewsSerializer, root: 'news',
            status: 201
        else
          render json: { errors: @news.errors.messages }, status: :unprocessable_entity
        end
      end

      def update
        @news = Content.find params[:id]
        # some unique validation
        # if it's already published, don't allow changing the pubdate (i.e. unpublishing or scheduling)
        if @news.pubdate.present? and @news.pubdate <= Time.zone.now and params[:news].has_key?(:pubdate)
          render json: { errors: { 'published_at' => 'Can\'t unpublish already published news' } },
            status: 500
        # don't allow publishing or scheduling without an organization
        elsif params[:news][:organization_id].blank? and @news.organization.blank? and params[:news][:pubdate].present?
          render json: { errors: { 'organization_id' => 'Organization must be specified for news' } },
            status: 500
        else
          if @news.update_attributes(params[:news])
            if @repository.present? and @news.pubdate.present?
              @news.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
            end

            render json: @news, serializer: DetailedNewsSerializer, root: 'news',
              status: 200
          else
            render json: { errors: @news.errors.messages }, status: :unprocessable_entity
          end
        end
      end

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
          allowed_orgs = @requesting_app.organizations.pluck(:id) 
          opts[:with][:org_id] = allowed_orgs

          if params[:organization].present? and params[:organization] != 'Everyone'
            org = Organization.find_by_name params[:organization]

            if org.present? and allowed_orgs.include? org.id
              opts[:with][:org_id] = [org.id]
            else
              render json: [], each_serializer: NewsSerializer and return
            end
          end
        else
          render json: [], each_serializer: NewsSerializer and return
        end

        if params[:location_id].present?
          opts[:with][:all_loc_ids] = params[:location_id].to_i
        end

        opts[:with][:root_content_category_id] = ContentCategory.find_by_name('news').id

        if params[:category].present?
          category = ContentCategory.find_by_name(params['category'].humanize.titleize)
          opts[:with][:content_category_id] = category.id if category
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
          @news.record_user_visit(@repository, @current_api_user.email) if @repository.present?
        else
          url = nil
        end

        if @news.try(:root_content_category).try(:name) != 'news'
          head :no_content
        else
          @news.increment_view_count!
          render json: @news, serializer: DetailedNewsSerializer, 
            admin_content_url: url, root: 'news'
        end
      end

      protected

      # translates API params to match internals
      def parse_params!
        params[:news][:raw_content] = params[:news].delete :content if params[:news].has_key? :content
        params[:news][:pubdate] = params[:news].delete :published_at if params[:news].has_key? :published_at
      end

    end
  end
end
