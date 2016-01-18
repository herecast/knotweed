module Api
  module V3
    class MarketPostsController < ApiController
      before_filter :check_logged_in!, only: [:create, :update]
      after_filter :track_index, only: :index
      after_filter :track_show, only: :show
      after_filter :track_create, only: :create
      after_filter :track_update, only: :update

      def index
        opts = {}
        opts = { select: '*, weight()' }
        opts[:order] = 'pubdate DESC'
        opts[:with] = {
          pubdate: 30.days.ago..Time.zone.now
        }
        opts[:conditions] = {}
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:with][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :publication, :root_content_category] }
        if @requesting_app.present?
          allowed_pubs = @requesting_app.publications
          opts[:with].merge!({pub_id: allowed_pubs.collect{|c| c.id} })
        end

        # Ember app passes location_id 0 for Upper Valley and an empty location_id
        # for 'All Communities'
        if params[:location_id] == 0
          opts[:with][:all_loc_ids] = Location.find_by_city(Location::DEFAULT_LOCATION).id
        elsif params[:location_id].present?
          opts[:with][:all_loc_ids] = params[:location_id].to_i
        end

        opts[:with][:root_content_category_id] = ContentCategory.find_by_name('market').id

        if params[:query].present?
          query = Riddle::Query.escape(params[:query]) 
        else
          query = ''
        end
        @market_posts = Content.search query, opts
        render json: @market_posts, each_serializer: MarketPostSerializer
      end

      def create
        market_cat = ContentCategory.find_by_name 'market'
        pub = Publication.find_or_create_by_name 'DailyUV'

        location_ids = [@current_api_user.location_id]
        if params[:market_post][:extended_reach_enabled]
          location_ids.push Location::REGION_LOCATION_ID
        end

        content_attributes = {
          title: params[:market_post][:title],
          raw_content: params[:market_post][:content],
          authoremail: @current_api_user.try(:email),
          authors: @current_api_user.try(:name),
          location_ids: location_ids,
          content_category_id: market_cat.id,
          pubdate: Time.zone.now,
          timestamp: Time.zone.now,
          publication_id: pub.id
        }
        listserv_ids = params[:market_post].delete :listserv_ids || []

        market_hash = { content_attributes: content_attributes }
        market_hash[:cost] = params[:market_post][:price]
        market_hash[:contact_phone] = params[:market_post][:contact_phone]
        market_hash[:contact_email] = params[:market_post][:contact_email]
        market_hash[:locate_address] = params[:market_post][:locate_address]

        @market_post = MarketPost.new(market_hash)
        if @market_post.save
          # reverse publish to specified listservs
          PromotionListserv.create_multiple_from_content(@market_post.content, listserv_ids, @requesting_app)

          if @repository.present?
            @market_post.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end

          render json: @market_post.content, serializer: DetailedMarketPostSerializer, can_edit: true,
            status: 201
        else
          render json: { errors: ["Market Post could not be created"] }, status: 500
        end
      end

      def update
        @market_post = Content.find(params[:id]).channel

        # TODO: once we have created_by, confirm that the user can edit this market post

        listserv_ids = params[:market_post].delete :listserv_ids || []

        location_ids = [@current_api_user.location_id]
        if params[:market_post][:extended_reach_enabled]
          location_ids.push Location::REGION_LOCATION_ID
        end

        @market_post.content.location_ids = location_ids
        @market_post.content.title = params[:market_post][:title] if params[:market_post][:title].present?
        @market_post.content.raw_content = params[:market_post][:content] if params[:market_post][:content].present?
        @market_post.cost = params[:market_post][:price] if params[:market_post][:price].present?
        @market_post.contact_phone = params[:market_post][:contact_phone] if params[:market_post][:contact_phone].present?
        @market_post.contact_email = params[:market_post][:contact_email] if params[:market_post][:contact_email].present?
        @market_post.locate_address = params[:market_post][:locate_address] if params[:market_post][:locate_address].present?

        if @market_post.save # NOTE: triggers @market_post.content.save via after_save callback as well
          # reverse publish to specified listservs
          PromotionListserv.create_multiple_from_content(@market_post.content, listserv_ids, @requesting_app)

          if @repository.present?
            @market_post.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end
          render json: @market_post.content, status: 200, 
            serializer: DetailedMarketPostSerializer, can_edit: true
        else
          render json: { errors: @market_post.errors.messages },
            status: :unprocessable_entity
        end
      end

      def show
        @market_post = Content.find params[:id]

        if @requesting_app.present?
          head :no_content and return unless @requesting_app.publications.include?(@market_post.publication)
        end

        if @market_post.try(:root_content_category).try(:name) != 'market'
          head :no_content
        else
          @market_post.increment_view_count!
          can_edit = (@current_api_user.present? && (@market_post.created_by == @current_api_user))
          render json: @market_post, serializer: DetailedMarketPostSerializer,
            can_edit: can_edit
        end
      end

      def contact
        @market_post = Content.find params[:id]

        if @market_post.try(:root_content_category).try(:name) != 'market'
          head :no_content
        elsif @market_post.try(:channel).is_a?(MarketPost)
          render json: { 
            market_post: {
              id: @market_post.channel_id,
              contact_email: @market_post.channel.contact_email,
              contact_phone: @market_post.channel.contact_phone
            }
          }
        else
          render json: {
            market_post: {
              id: @market_post.id,
              contact_email: @market_post.authoremail,
              contact_phone: nil 
            }
          }
        end
      end

      private

      def track_index
        props = {}
        props.merge! @tracker.navigation_properties('Market', 'market.index', url_for, params)
        props.merge! @tracker.search_properties(params)
        @tracker.track(@mixpanel_distinct_id, 'searchContent', @current_api_user, props)
      end

      def track_show
        props = {}
        props.merge! @tracker.navigation_properties('Market', 'market.show', url_for, params) 
        props.merge! @tracker.content_properties(@market)
        @tracker.track(@mixpanel_distinct_id, 'selectContent', @current_api_user, props)
      end

      def track_create
        props = {}
        props.merge! @tracker.content_properties(@market_post)
        props.merge! @tracker.content_creation_properties('create')
        @tracker.track(@mixpanel_distinct_id, 'submitContent', @current_api_user, props)
      end

      def track_update
        props = {}
        props.merge! @tracker.navigation_properties('Market', 'market.index', url_for, params)
        props.merge! @tracker.content_properties(@market_post)
        props.merge! @tracker.content_creation_properties('edit')
        @tracker.track(@mixpanel_distinct_id, 'submitContent', @current_api_user, props)
      end

    end
  end
end
