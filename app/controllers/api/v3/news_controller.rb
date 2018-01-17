module Api
  module V3
    class NewsController < ApiController
      before_filter :check_logged_in!, only: [:create, :update, :destroy]

      def create
        np = news_params
        news_cat = ContentCategory.find_or_create_by(name: 'news')
        @news = Content.new(np.merge(content_category_id: news_cat.id, origin: Content::UGC_ORIGIN))
        if @news.save
          if @repository.present? and @news.pubdate.present? # don't publish drafts
            PublishContentJob.perform_later(@news, @repository, Content::DEFAULT_PUBLISH_METHOD)
          end

          render json: @news, serializer: DetailedNewsSerializer, root: 'news',
            status: 201
        else
          render json: { errors: @news.errors.messages }, status: :unprocessable_entity
        end
      end

      def update
        @news = Content.find params[:id]
        authorize! :update, @news
        np = news_params
        # some unique validation
        # if it's already published, don't allow changing the pubdate (i.e. unpublishing or scheduling)
        if @news.pubdate.present? and @news.pubdate <= Time.zone.now and np.has_key?(:pubdate) \
            and Chronic.parse(np[:pubdate]).to_i != @news.pubdate.to_i
          render json: { errors: { 'published_at' => 'Can\'t unpublish already published news' } },
            status: 500
        # don't allow publishing or scheduling without an organization
        elsif np[:organization_id].blank? and @news.organization.blank? and np[:pubdate].present?
          render json: { errors: { 'organization_id' => 'Organization must be specified for news' } },
            status: 500
        else
          if @news.update_attributes(np)
            if @repository.present? and @news.pubdate.present?
              PublishContentJob.perform_later(@news, @repository, Content::DEFAULT_PUBLISH_METHOD)
            end

            conditionally_cache_with_facebook

            render json: @news, serializer: DetailedNewsSerializer, root: 'news',
              status: 200
          else
            render json: { errors: @news.errors.messages }, status: :unprocessable_entity
          end
        end
      end

      def index
        expires_in 1.minutes, public: true
        opts = Content.default_search_opts
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 12
        opts[:where] = { removed: { not: true } }
        opts[:where][:published] = 1 if @repository.present?

        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations.pluck(:id)
          opts[:where][:organization_id] = allowed_orgs

          if (params[:organization].present? and params[:organization] != 'Everyone') or params[:organization_id].present?

            if params[:organization].present?
              org = Organization.find_by_name params[:organization]
            elsif params[:organization_id].present?
              org = Organization.find params[:organization_id]
            end

            if org.present? and allowed_orgs.include? org.id
              org_ids = Organization.descendants_of(org.id).news_publishers.pluck(:id) + [org.id]
              opts[:where][:organization_id] = org_ids.compact.uniq
            else
              render json: [], each_serializer: NewsSerializer and return
            end
          end
        else
          render json: [], each_serializer: NewsSerializer and return
        end

        add_location_query(opts) if params[:location_id].present?

        opts[:where][:root_content_category_id] = ContentCategory.find_by_name('news').id

        if params[:category].present?
          category = ContentCategory.find_by_name(params['category'].humanize.titleize)
          opts[:where][:content_category_id] = category.id if category
        end

        query = params[:query].present? ? params[:query] : '*'

        @news = Content.search query, opts
        render json: @news, each_serializer: NewsSerializer,
          meta: {total: @news.total_entries}
      end

      def show
        @news = Content.not_deleted.find params[:id]

        # filter out orgs that don't belong with this app
        # have to still allow drafts that haven't selected their org yet, though
        if @requesting_app.present? and @news.organization.present?
          return render json: {}, :status => 404 unless @requesting_app.organizations.include?(@news.organization)
        end

        if @current_api_user.present?
          url = edit_content_url(@news) if @current_api_user.has_role? :admin
        else
          url = nil
        end

        if @news.try(:root_content_category).try(:name) != 'news'
          render json: {}, :status => 404
        else
          render json: @news, serializer: DetailedNewsSerializer,
            admin_content_url: url, root: 'news', context: { current_ability: current_ability }
        end
      end

      def destroy
        @news = Content.find params[:id]
        authorize! :destroy, @news
        is_news_category = @news.try(:root_content_category).try(:name) == 'news'

        if is_news_category #@TODO <- Do we need to check consumer app here?
          @news.update_attribute(:deleted_at, Time.current)
          head :no_content
        else
          head :not_found
        end
      end

      protected

      def news_params
        transformed_params.require(:news).permit(
          :raw_content, :pubdate, :authors,
          :organization_id, :title, :subtitle,
          :authors_is_created_by,
          :promote_base_location_id,
          :promote_radius,
          content_locations_attributes: [:id, :location_id, :location_type]
        )
      end

      def transformed_params
        ActionController::Parameters.new(params).tap do |h|
          h[:news][:raw_content] = h[:news].delete :content if h[:news].has_key? :content
          h[:news][:pubdate] = h[:news].delete :published_at if h[:news].has_key? :published_at
          author_name = h[:news].delete :author_name

          if @news.present? # update scenario, news already exists and has an author who may not be the current user
            h[:news][:authors_is_created_by] = true if @news.created_by.try(:name) == author_name
          elsif author_name == @current_api_user.name # @news hasn't been persisted yet so has no created_by
            # which means the current user IS the author
            h[:news][:authors_is_created_by] = true
          end

          unless h[:news][:authors_is_created_by]
            h[:news][:authors_is_created_by] = false
            h[:news][:authors] = author_name
          end

          if h[:news][:content_locations].present?
            translate_content_locations_params h
          end
        end
      end

      def add_location_query(opts)
        if params[:location_id].present?
          opts[:where][:or] ||= []
          location = Location.find_by_slug_or_id params[:location_id]

          if params[:radius].present? && params[:radius].to_i > 0
            locations_within_radius = Location.within_radius_of(location, params[:radius].to_i).map(&:id)

            opts[:where][:or] << [
              {my_town_only: false, all_loc_ids: locations_within_radius},
              {my_town_only: true, all_loc_ids: location.id}
            ]
          else
            opts[:where][:or] << [
              {about_location_ids: [location.id]},
              {base_location_ids: [location.id]}
            ]
          end
        end
      end

      def translate_content_locations_params(data)
        if data[:news][:content_locations]
          data[:news][:content_locations_attributes] = data[:news].delete(:content_locations).tap do |h|
            # translate slug to id
            h.each do |content_location|
              content_location[:location_id] = Location.find_by(slug: content_location[:location_id]).try(:id)
            end
          end
        end
      end

      def conditionally_cache_with_facebook
        if @news.pubdate.present? && @news.pubdate < Time.current
          BackgroundJob.perform_later('FacebookService', 'rescrape_url', @news)
        end
      end

    end
  end
end
