module Api
  module V3
    class ContentsController < ApiController
      before_filter :check_logged_in!, only:  [:moderate, :dashboard, :metrics]

      def index
        expires_in 1.minutes, public: true unless is_my_stuff_request?
        render json: { feed_items: [] }, status: :ok and return if is_my_stuff_request? && current_user.nil?

        @result_object = GatherFeedRecords.call(
          params: params,
          requesting_app: @requesting_app,
          current_user: current_user
        )

        render json: FeedContentVanillaSerializer.call(
          records: @result_object[:records],
          opts: { context: { current_ability: current_ability } }
        ).merge(
          meta: {
            total: @result_object[:total_entries],
            total_pages: total_pages
          }
        )
      end

      # For usage in sitemap generation
      def sitemap_ids
        types=(params[:type] || "news,market,talk").split(/,\s*/).map do |type|
          if type == 'talk'
            'talk_of_the_town'
          else
            type
          end
        end

        content_ids = Content.published.not_deleted.not_listserv.not_removed.is_dailyuv\
          .only_categories(types)\
          .order('pubdate DESC')\
          .limit(50_000)\
          .pluck(:id)

        render json: {content_ids: content_ids}
      end

      def show
        expires_in 1.minutes, public: true

        @content = Content.find(params[:id])
        if @content.is_listserv? && !user_signed_in?
          render json: {}, status: :unauthorized
          return
        end

        if @requesting_app.present? && @requesting_app.organizations.include?(@content.organization)
          @content = @content.removed == true ? CreateAlternateContent.call(@content) : @content
          render json: @content, serializer: ContentSerializer,
            context: { current_ability: current_ability }
        else
          render json: {}, status: :not_found
        end
      end

      def update
        @content = Content.find(params[:id])
        authorize! :update, @content
        if @content.update_attributes(content_params)
          render json: @content, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def similar_content
        expires_in 1.minutes, :public => true
        @content = Content.find params[:id]

        # need to call to_a here so we can use mutating select! afterwards
        # (Rails 4.1 deprecated calling mutating methods directly on ActiveRecord
        # Relations)
        @contents = @content.similar_content(@repository, 20).to_a
        # filter by organization
        if @requesting_app.present?
          requesting_app_orgs = @requesting_app.organizations.to_a
          @contents.select!{ |c| requesting_app_orgs.map(&:id).include? c.organization.id }
        end

        # remove records that are events with no future instances
        @contents.reject! do |c|
          c.channel_type == 'Event' &&
            c.event_instances.all? { |ei| ei.start_date <= Time.zone.now }
        end

        # remove drafts and future scheduled content
        @contents.reject!{ |c| c.pubdate.nil? or c.pubdate >= Time.zone.now }

        # This is a Bad temporary hack to allow filtering the sim stack provided by apiv2
        # the same way that the consumer app filters it.
        if Figaro.env.sim_stack_categories?
          @contents.select! do |c|
            name = c.content_category_name
            name && Figaro.env.sim_stack_categories.include?(name)
          end
        end

        @contents = @contents.slice(0,8)

        render json: @contents, each_serializer: HashieMashes::FeedContentSerializer,
          root: 'similar_content', consumer_app_base_uri: @requesting_app.try(:uri)
      end

      def moderate
        content = Content.find(params[:id])
        ModerationMailer.send_moderation_flag_v2(content, params[:flag_type], \
          @current_api_user).deliver_later
        head :no_content
      end

      # returns all types of content
      def dashboard
        params[:sort] ||= 'pubdate DESC'
        params[:page] ||= 1
        params[:per_page] ||= 12

        if params[:organization_id].present? and can? :manage, Organization.find(params[:organization_id])
          org_id = params[:organization_id]
          hierarchical_org_ids = Organization.descendants_of(org_id).news_publishers.pluck(:id) + [org_id]
          scope = Content.where(organization_id: hierarchical_org_ids)
        else
          scope = Content.where(created_by: @current_api_user)
        end

        scope = scope.not_deleted

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

        # if requested to sort by pubdate, sort is actually fairly complex because
        # we want drafts to appear based on their created_by in the midst of published
        # content sorted by pubdate
        if sort_by.include? 'pubdate'
          scope = scope.select("CASE WHEN pubdate IS NULL THEN updated_at ELSE pubdate END as sort_date, contents.*")
          sort_by.gsub!('pubdate', 'sort_date')
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

        def content_params
          params.require(:content).permit(:biz_feed_public, :sunset_date)
        end

        def per_page
          params[:per_page] || 20
        end

        def total_pages
          @result_object[:total_entries].present? ? (@result_object[:total_entries]/per_page.to_f).ceil : nil
        end

        def sanitize_sort_parameter(sort)
          sort_parts = sort.split(',')
          sort_parts.select! do |pt|
            pt.match /\A([a-zA-Z]+_)?[a-zA-Z]+ (ASC|DESC)/
          end
          sort_query = sort_parts.join(',').gsub('channel_type', 'root_category.name')
          sort_query.gsub('start_date', 'pubdate')
        end

        def is_my_stuff_request?
          ['me', 'my_stuff', 'mystuff'].include?(params[:radius].to_s.downcase)
        end
    end
  end
end
