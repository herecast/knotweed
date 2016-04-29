module Api
  module V3
    class ContentsController < ApiController
      before_filter :check_logged_in!, only:  [:moderate, :dashboard, :metrics]
      # pings the DSP to retrieve an active related banner ad (with inventory) for a generic
      # content type.
      def related_promotion
        @content = Content.find params[:id]
        # get related promo if exists
        @banner, select_score, select_method = @content.get_related_promotion(@repository)

        unless @banner.present? # banner must've expired or been used up since repo last updated
          render json: {}
        else
          # log banner ad impression with associated details
          ContentPromotionBannerImpression.log_impression(@content.id, @banner.id,
                                                          select_method, select_score)
          # increment promotion_banner counts for impressions and daily_impressions
          unless @current_api_user.try(:skip_analytics?)
            @banner.increment_integer_attr! :impression_count
            @banner.increment_integer_attr! :daily_impression_count
          end
          render json:  { related_promotion:
            { 
              image_url: @banner.banner_image.url, 
              redirect_url: @banner.redirect_url,
              banner_id: @banner.id
            }
          }
        end

      end

      def similar_content
        @content = Content.find params[:id]

        # need to call to_a here so we can use mutating select! afterwards
        # (Rails 4.1 deprecated calling mutating methods directly on ActiveRecord
        # Relations)
        @contents = @content.similar_content(@repository, 20).to_a

        # filter by organization
        if @requesting_app.present?
          @contents.select!{ |c| @requesting_app.organizations.include? c.organization }
        end

        # remove records that are events with no future instances
        @contents.reject!{ |c| c.channel_type == 'Event' && c.channel.next_instance.blank?}

        # remove drafts and future scheduled content
        @contents.reject!{ |c| c.pubdate.nil? or c.pubdate >= Time.zone.now }

        # This is a Bad temporary hack to allow filtering the sim stack provided by apiv2
        # the same way that the consumer app filters it. 
        if Figaro.env.respond_to? :sim_stack_categories
          @contents.select! do |c|
            Figaro.env.sim_stack_categories.include? c.content_category.name
          end
        end

        @contents = @contents.slice(0,8)

        render json: @contents, each_serializer: ContentSerializer,
          root: 'similar_content', consumer_app_base_uri: @requesting_app.try(:uri)

      end

      def moderate
        content = Content.find(params[:id])
        ModerationMailer.send_moderation_flag_v2(content, params[:flag_type], \
          @current_api_user).deliver_now
        head :no_content
      end

      def index
        # by default, each page has two news items and twelve other items
        # we accept `per_page` and/or `news_per_page` params that allow tweaking
        # that and automatically limit the total response to 14 entries if only one per_page
        # param is passed
        if params[:per_page].present? and params[:news_per_page].present?
          per_page = params[:per_page]
          news_per_page = params[:news_per_page]
        elsif params[:per_page].present?
          per_page = params[:per_page].to_i
          news_per_page = 14 - per_page
        elsif params[:news_per_page].present?
          news_per_page = params[:news_per_page]
          per_page = 14 - news_per_page
        else
          per_page = 12
          news_per_page = 2
        end
        opts = { select: '*, weight()' }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:with][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :organization, :root_content_category] }

        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:with].merge!({org_id: allowed_orgs.collect{|c| c.id} })
        end

        default_location_id = Location.find_by_city(Location::DEFAULT_LOCATION).id
        location_condition = @current_api_user.try(:location_id) || default_location_id

        root_news_cat = ContentCategory.find_by_name 'news'
        news_opts = opts.merge({ 
          per_page: news_per_page
        })
        news_opts[:with] = news_opts[:with].merge({
          root_content_category_id: root_news_cat.id,
          all_loc_ids: [location_condition]
        })

        # is this slower than a single query that retrieves all 4 using 'name IN (...)'?
        # I doubt it.
        reg_cat_ids = [ContentCategory.find_by_name('market').id,
                       ContentCategory.find_by_name('event').id]
        # if signed in, include talk.
        if @current_api_user.present?
          reg_cat_ids += [ContentCategory.find_by_name('talk_of_the_town').id]
        end

        reg_opts = opts.merge({
          per_page: per_page
        })
        reg_opts[:with] = reg_opts[:with].merge({
          all_loc_ids: [location_condition],
          root_content_category_id: reg_cat_ids
        })

        root_market_category = ContentCategory.find_by(name: 'market')
        reg_opts[:select] = reg_opts[:select] +  ",IF(root_content_category_id = #{root_market_category.id} AND  channel_type='', 1, 0) AS is_listserv_market_post"
        reg_opts[:without] = { is_listserv_market_post: 1 }

        news_contents = Content.search news_opts
        reg_contents = Content.search reg_opts

        # note: can't combine these two relations without converting them to arrays
        # because thinking sphinx
        @contents = news_contents.to_a + reg_contents.to_a

        render json: @contents, each_serializer: ContentSerializer

      end

      # returns all types of content
      def dashboard
        params[:sort] ||= 'pubdate DESC'
        params[:page] ||= 1
        params[:per_page] ||= 12

        if params[:organization_id].present? and can? :manage, Organization.find(params[:organization_id])
          scope = Content.where(organization_id: params[:organization_id])
        else
          scope = Content.where(created_by: @current_api_user)
        end

        @news_cat = ContentCategory.find_or_create_by(name: 'news')
        @talk_cat = ContentCategory.find_or_create_by(name: 'talk_of_the_town')
        @market_cat = ContentCategory.find_or_create_by(name: 'market')

        if params[:channel_type] == 'news'
          scope = scope.where(root_content_category_id: @news_cat.id)
        elsif params[:channel_type] == 'events'
          scope = scope.where(channel_type: 'Event')
        elsif params[:channel_type] == 'talk'
          scope = scope.where(root_content_category_id: @talk_cat.id)
        elsif params[:channel_type] == 'market'
          scope = scope.where(root_content_category_id: @market_cat.id)
        else # default -- include any of the above
          scope = scope.where("root_content_category_id IN (?) OR channel_type = 'Event'", [@news_cat.id, @talk_cat.id, @market_cat.id])
        end

        sort_by = sanitize_sort_parameter(params[:sort])

        if sort_by.include?('root_category')
          scope = scope.joins('
            join content_categories as root_category
                on root_category.id = contents.root_content_category_id')
        end

        @contents = scope.if_event_only_when_instances
                         .order(sort_by)
                         .page(params[:page].to_i)
                         .per(params[:per_page].to_i)

        render json: @contents, each_serializer: DashboardContentSerializer
      end

      def metrics
        @content = Content.find(params[:id])
        authorize! :manage, @content
        render json: @content, serializer: ContentMetricsSerializer, 
          context: {start_date: params[:start_date], end_date: params[:end_date]}
      end

      protected

      def sanitize_sort_parameter(sort)
        sort_parts = sort.split(',')
        sort_parts.select! do |pt|
          pt.match /\A([a-zA-Z]+_)?[a-zA-Z]+ (ASC|DESC)/
        end
        sort_parts.join(',').gsub('channel_type', 'root_category.name')
      end

    end
  end
end
