module Api
  module V3
    class MarketPostsController < ApiController
      before_filter :check_logged_in!, only: [:create, :update]

      def index
        expires_in 1.minutes, public: true
        opts = {}
        opts[:order] = { pubdate: :desc }
        opts[:where] = {
          pubdate: 30.days.ago..Time.zone.now
        }
        # market local only restriction
        # if a user is signed in, we allow showing "restricted content" if it's
        # restricted to their location (and if other search params allow it to be
        # included).
        if user_signed_in?
          opts[:where][:or] = [
            [{my_town_only: false}, {all_loc_ids: [@current_user.location_id]}]
          ]
        else
          # if a user is not signed in, we do not show location restricted content at all.
          opts[:where][:my_town_only] = false
        end
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:where][:published] = 1 if @repository.present?
        opts[:where][:channel_type] = 'MarketPost' if params[:has_image].present? && params[:has_image] == "true"

        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:where][:organization_id] = allowed_orgs.collect{|c| c.id}
        end

        # Ember app passes location_id 0 for Upper Valley and an empty location_id
        # for 'All Communities'
        # the .present? condition is to deal with the parameter being empty
        if params[:location_id].present? and params[:location_id].to_i == 0
          opts[:where][:all_loc_ids] = Location.find_by_city(Location::DEFAULT_LOCATION).id
        elsif params[:location_id].present?
          opts[:where][:all_loc_ids] = params[:location_id].to_i
        end

        opts[:where][:root_content_category_id] = ContentCategory.find_by_name('market').id

        # includes tables to eliminate n+1 queries
        opts[:includes] = [:channel, :root_content_category, :created_by, :created_by, :images]

        query = params[:query].present? ? params[:query] : '*'

        @market_posts = Content.search query, opts
        render json: @market_posts, each_serializer: DetailedMarketPostSerializer, meta: { total: @market_posts.total_count }
      end

      def create
        @market_post = MarketPost.new(market_post_params)
        if @market_post.save
          # reverse publish to specified listservs
          listserv_ids = params[:market_post][:listserv_ids] || []
          PromotionListserv.create_multiple_from_content(@market_post.content, listserv_ids, @requesting_app)

          PublishContentJob.perform_later(@market_post.content, @repository, Content::DEFAULT_PUBLISH_METHOD) if @repository.present?

          render json: @market_post.content, serializer: DetailedMarketPostSerializer,
            status: 201, context: { current_ability: current_ability }
        else
          render json: { errors: ["Market Post could not be created"] }, status: 500
        end
      end

      def update
        @market_post = Content.find(params[:id]).channel
        authorize! :manage, @market_post.content
        if @market_post.update_attributes(market_post_params)
          # reverse publish to specified listservs
          listserv_ids = params[:market_post][:listserv_ids] || []
          PromotionListserv.create_multiple_from_content(@market_post.content, listserv_ids, @requesting_app)
          
          PublishContentJob.perform_later(@market_post.content, @repository, Content::DEFAULT_PUBLISH_METHOD) if @repository.present?

          render json: @market_post.content, status: 200,
            serializer: DetailedMarketPostSerializer, context: { current_ability: current_ability }
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
          @market_post.increment_view_count! unless exclude_from_impressions?
          if @current_api_user.present? and @repository.present?
            BackgroundJob.perform_later_if_redis_available('DspService', 'record_user_visit', @market_post,
                                                           @current_api_user, @repository)
          end
          render json: @market_post, serializer: DetailedMarketPostSerializer,
            context: { current_ability: current_ability }
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

        def market_post_params
          new_params = params
          attributes = @market_post.present? ? additional_update_attributes : additional_create_attributes
          new_params[:market_post].merge!(attributes)
          new_params.require(:market_post).permit(
            :contact_email,
            :contact_phone,
            :contact_url,
            :cost,
            :latitude,
            :longitude,
            :locate_address,
            :locate_include_name,
            :locate_name,
            :status,
            :prefered_contact_method,
            :sold,
            content_attributes: [
              :id,
              :title,
              :raw_content,
              :authoremail,
              :authors,
              :content_category_id,
              :pubdate,
              :timestamp,
              :organization_id,
              :my_town_only,
              location_ids: []
            ]
          )
        end

        def additional_create_attributes
          {
            cost: params[:market_post][:price],
            content_attributes: {
              title: params[:market_post][:title],
              raw_content: params[:market_post][:content],
              authoremail: @current_api_user.try(:email),
              authors: @current_api_user.try(:name),
              location_ids: [@current_api_user.location_id],
              content_category_id: ContentCategory.find_or_create_by(name: 'market').id,
              pubdate: Time.zone.now,
              timestamp: Time.zone.now,
              organization_id: params[:market_post][:organization_id] || Organization.find_or_create_by(name: 'DailyUV').id,
              my_town_only: params[:market_post].delete(:my_town_only)
            }
          }
        end

        def additional_update_attributes
          additional_attributes = {
            cost: params[:market_post][:price],
            content_attributes: {
              id: params[:id],
              location_ids: [@current_api_user.location_id],
              title: params[:market_post][:title],
              raw_content: params[:market_post][:content]
            }
          }

          if params[:market_post][:extended_reach_enabled].present?
            additional_attributes[:content_attributes][:location_ids].push(Location::REGION_LOCATION_ID)
          end

          additional_attributes
        end

    end
  end
end
