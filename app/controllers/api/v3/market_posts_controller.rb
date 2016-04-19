module Api
  module V3
    class MarketPostsController < ApiController
      before_filter :check_logged_in!, only: [:create, :update]

      def index
        opts = {}
        opts[:order] = 'pubdate DESC'
        opts[:with] = {
          pubdate: 30.days.ago..Time.zone.now
        }
        opts[:conditions] = {}
        # market local only restriction
        # if a user is signed in, we allow showing "restricted content" if it's
        # restricted to their location (and if other search params allow it to be 
        # included).
        if user_signed_in?
          opts[:select] = "*, IF(my_town_only = 0 OR IN(all_loc_ids, #{@current_user.location_id}), 1, 0) AS local_restriction"
          opts[:with]['local_restriction'] = 1
        else
          # if a user is not signed in, we do not show location restricted content at all.
          opts[:select] = "*"
          opts[:with][:my_town_only] = false
        end
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:with][:published] = 1 if @repository.present?
        opts[:sql] = { include: [:images, :organization, :root_content_category] }
        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:with].merge!({org_id: allowed_orgs.collect{|c| c.id} })
        end

        # Ember app passes location_id 0 for Upper Valley and an empty location_id
        # for 'All Communities'
        # the .present? condition is to deal with the parameter being empty
        if params[:location_id].present? and params[:location_id].to_i == 0
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

        if params[:market_post][:organization_id].present?
          org_id = params[:market_post].delete :organization_id
        else
          org_id = Organization.find_or_create_by(name: 'DailyUV').id
        end

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
          organization_id: org_id
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

          render json: @market_post.content, serializer: DetailedMarketPostSerializer, can_edit: can?(:edit, @market_post.content),
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
        if params[:market_post].delete :extended_reach_enabled
          location_ids.push Location::REGION_LOCATION_ID
        end

        params[:market_post][:content_attributes] = { location_ids: location_ids, id: params[:id] }
        params[:market_post][:content_attributes][:title] = params[:market_post].delete :title if params[:market_post].has_key? :title
        params[:market_post][:content_attributes][:raw_content] = params[:market_post].delete :content if params[:market_post].has_key? :content
        params[:market_post][:cost] = params[:market_post].delete :price if params[:market_post].has_key? :price

        if @market_post.update_attributes(params[:market_post])
          # reverse publish to specified listservs
          PromotionListserv.create_multiple_from_content(@market_post.content, listserv_ids, @requesting_app)

          if @repository.present?
            @market_post.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end
          render json: @market_post.content, status: 200, 
            serializer: DetailedMarketPostSerializer, can_edit: can?(:edit, @market_post.content)
        else
          render json: { errors: @market_post.errors.messages },
            status: :unprocessable_entity
        end
      end

      def show
        @market_post = Content.find params[:id]

        if @requesting_app.present?
          head :no_content and return unless @requesting_app.organizations.include?(@market_post.organization)
        end

        if @market_post.try(:root_content_category).try(:name) != 'market'
          head :no_content
        else
          @market_post.increment_view_count!
          if @current_api_user.present? and @repository.present?
            @market_post.record_user_visit(@repository, @current_api_user.email)
          end
          can_edit = can?(:edit, @market_post)
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

    end
  end
end
