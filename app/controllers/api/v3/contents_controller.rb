module Api
  module V3
    class ContentsController < ApiController
      before_filter :check_logged_in!, only:  [:moderate, :dashboard, :ad_dashboard, :metrics]
      after_filter :track_moderate, only: :moderate
      # pings the DSP to retrieve an active related banner ad (with inventory) for a generic
      # content type.
      def related_promotion
        @content = Content.find params[:id]
        # get related promo if exists
        results = @content.get_related_promotion(@repository)
        # if exists, grab content_id, score and select method (for logging)
        if results.present?
          c_id = results[:id]
          select_score = results[:score]
          select_method = results[:select_method]
          @banner = PromotionBanner.for_content(c_id).has_inventory.first(:order => "RAND()")
        else
          # if not, try to get a random active 'boosted' promo with inventory
          select_score = nil
          select_method = "boost"
          @banner = PromotionBanner.active.boost.has_inventory.first(:order => "RAND()")
          # if not, try to get a random active 'paid' promo with inventory
          select_method = "paid" unless @banner.present?
          @banner = PromotionBanner.active.paid.has_inventory.first(:order => "RAND()") unless @banner.present?
          # if not, try to get a random active promo with inventory
          select_method = "active" unless @banner.present?
          @banner = PromotionBanner.active..has_inventory.first(:order => "RAND()") unless @banner.present?
          # if not, try to get a random active promo
          select_method = "active no inventory" unless @banner.present?
          @banner = PromotionBanner.active.first(:order => "RAND()") unless @banner.present?
        end

        unless @banner.present? # banner must've expired or been used up since repo last updated
          render json: {}
        else
          # log banner ad impression with associated details
          ContentPromotionBannerImpression.log_impression(@content.id, @banner.id, select_method, select_score)
          # increment promotion_banner counts for impressions and daily_impressions
          @banner.increment_integer_attr! :impression_count
          @banner.increment_integer_attr! :daily_impression_count
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

        @contents = @content.similar_content(@repository, 20)

        # filter by publication
        if @requesting_app.present?
          @contents.select!{ |c| @requesting_app.publications.include? c.publication }
        end

        #choose records that are events with instances in the future
        @contents.select!{ |c| c.channel_type == 'Event' && c.channel.next_instance.present?}

        # This is a Bad temporary hack to allow filtering the sim stack provided by apiv2
        # the same way that the consumer app filters it. 
        if Figaro.env.respond_to? :sim_stack_categories
          @contents.select! do |c|
            Figaro.env.sim_stack_categories.include? c.content_category.name
          end
        end

        @contents = @contents.slice(0,6)

        render json: @contents, each_serializer: ContentSerializer,
          root: 'similar_content', consumer_app_base_uri: @requesting_app.try(:uri)

      end

      def moderate
        content = Content.find(params[:id])
        ModerationMailer.send_moderation_flag_v2(content, params[:flag_type], \
          @current_api_user).deliver
        head :no_content
      end

      def index
        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {}
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:with][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :publication, :root_content_category] }

        if @requesting_app.present?
          allowed_pubs = @requesting_app.publications
          opts[:with].merge!({pub_id: allowed_pubs.collect{|c| c.id} })
        end

        default_location_id = Location.find_by_city(Location::DEFAULT_LOCATION).id
        location_condition = @current_api_user.try(:location_id) || default_location_id

        root_news_cat = ContentCategory.find_by_name 'news'
        news_opts = opts.merge({ 
          per_page: 2
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
          per_page: 12
        })
        reg_opts[:with] = reg_opts[:with].merge({
          all_loc_ids: [location_condition],
          root_content_category_id: reg_cat_ids
        })

        news_contents = Content.search news_opts
        reg_contents = Content.search reg_opts

        # note: can't combine these two relations without converting them to arrays
        # because thinking sphinx
        @contents = news_contents.to_a + reg_contents.to_a

        render json: @contents, each_serializer: ContentSerializer

      end

      def dashboard
        params[:sort] ||= 'pubdate DESC'
        params[:page] ||= 1
        params[:per_page] ||= 12

        @contents = Content.where(created_by: @current_api_user). #, channel_type: ["Event", "MarketPost", "Comment"]).
          order(sanitize_sort_parameter(params[:sort])).
          page(params[:page].to_i).per(params[:per_page].to_i)

        @contents.select! do |c|
          if c.channel_type == 'Event'
            c.channel.event_instances.count > 0
          else
            true
          end
        end

        render json: @contents, each_serializer: DashboardContentSerializer

      end

      # returns all types of content
      def ad_dashboard
        params[:sort] ||= 'pubdate DESC'

        reg_conts = Content.where(created_by: @current_api_user).
          order(sanitize_sort_parameter(params[:sort]))

        banners = PromotionBanner.joins(:promotion).
          where('promotions.created_by = ? and promotable_type = "PromotionBanner"',
                @current_api_user.id)

        @contents = reg_conts + banners

        render json: @contents, serializer: AdDashboardArraySerializer
      end

      def metrics
        @content = Content.find(params[:id])
        # confirm user owns content first
        if @current_api_user != @content.created_by 
          render json: { errors: ['You do not have permission to access these metrics.'] }, 
            status: 401
        else
          render json: @content, serializer: ContentMetricsSerializer
        end
      end

      protected

      def sanitize_sort_parameter(sort)
        sort_parts = sort.split(',')
        sort_parts.select! do |pt|
          pt.match /\A([a-zA-Z]+_)?[a-zA-Z]+ (ASC|DESC)/
        end
        sort_parts.join(',')
      end

      private

      def track_moderate
        @tracker.track(@mixpanel_distinct_id, 'moderateContent', @current_api_user, Hash.new)
      end

    end
  end
end
