module Api
  module V3
    class MarketPostsController < ApiController

      before_filter :check_logged_in!, only: [:create] 

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
        elsif @current_api_user.present? and @current_api_user.location_id.present?
          location_condition = @current_api_user.location_id
        else
          location_condition = Location.find_by_city(Location::DEFAULT_LOCATION).id
        end

        root_news_cat = ContentCategory.find_by_name 'market'

        opts[:with].merge!({
          all_loc_ids: [location_condition], 
          root_content_category_id: root_news_cat.id
        })

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
        content_attributes = {
          title: params[:market_post].delete(:title),
          raw_content: params[:market_post].delete(:content),
          content_category_id: market_cat.id,
          pubdate: Time.zone.now,
          timestamp: Time.zone.now
        }
        listserv_ids = params[:market_post].delete :listserv_ids
        map_parameter_names!
        params[:market_post][:content_attributes] = content_attributes

        @market_post = MarketPost.new(params[:market_post])

        if @market_post.save
          # reverse publish to specified listservs
          if listserv_ids.present?
            listserv_ids.each do |d|
              next if d.empty?
              list = Listserv.find(d.to_i)
              PromotionListserv.create_from_content(@market_post.content, list, @requesting_app) if list.present? and list.active
            end
          end
          if @repository.present?
            @market_post.publish(Content::DEFAULT_PUBLISH_METHOD, repo)
          end

          render json: @market_post, serializer: DetailedMarketPostSerializer, can_edit: true,
            status: 201
        else
          render json: { errors: "Market Post could not be created" }, status: 500
        end
      end

      def show
        @market_post = Content.find params[:id]

        if @market_post.try(:root_content_category).try(:name) != 'market'
          head :no_content
        else
          # NOTE: need to uncomment this line when created_by is available and delete
          # the line after it
          #can_edit = (@market_post.created_by == @current_api_user)
          can_edit = false
          render json: @market_post, serializer: DetailedMarketPostSerializer,
            can_edit: can_edit
        end
      end

      def contact
        @market_post = Content.find params[:id]
        if !@market_post.try(:channel).is_a?(MarketPost)
          head :no_content
        else
          render json: { 
            market_post: {
              id: @market_post.channel_id,
              contact_email: @market_post.channel.contact_email,
              contact_phone: @market_post.channel.contact_phone
            }
          }
        end
      end

      private

      # maps Ember app parameter names to our actual field names
      def map_parameter_names!
        params[:market_post][:cost] = params[:market_post].delete :price
      end

    end
  end
end
