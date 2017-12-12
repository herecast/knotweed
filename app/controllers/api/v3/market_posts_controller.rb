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

        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:where][:published] = 1 if @repository.present?
        opts[:where][:channel_type] = 'MarketPost' if params[:has_image].present? && params[:has_image] == "true"

        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:where][:organization_id] = allowed_orgs.collect{|c| c.id}
        end

        if params[:location_id].present?
          opts[:where][:or] ||= []
          location = Location.find_by_slug_or_id(params[:location_id])

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

        opts[:where][:root_content_category_id] = ContentCategory.find_by_name('market').id

        # includes tables to eliminate n+1 queries
        opts[:includes] = [:channel, :root_content_category, :created_by, :created_by, :images, :locations, :content_locations]

        query = params[:query].present? ? params[:query] : '*'

        modifier = set_modifier_for_category(params[:query_modifier]) unless params[:query_modifier].blank?
        modifier ||= {}

        @market_posts = Content.search formatted_query(query), opts.merge(modifier)
        render json: @market_posts, each_serializer: DetailedMarketPostSerializer, meta: { total: @market_posts.total_count }, context: { current_ability: current_ability }
      end

      def create
        @market_post = MarketPost.new(market_post_params)

        update_locations @market_post

        if @market_post.save
          listserv_ids = params[:market_post][:listserv_ids] || []
          if listserv_ids.any?
            # reverse publish to specified listservs
            PromoteContentToListservs.call(
              @market_post.content,
              @requesting_app,
              request.remote_ip,
              *Listserv.where(id: listserv_ids)
            )
          end

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

        update_locations @market_post

        if @market_post.update_attributes(market_post_params)
          listserv_ids = params[:market_post][:listserv_ids] || []
          if listserv_ids.any?
            # reverse publish to specified listservs
            PromoteContentToListservs.call(
              @market_post.content,
              @requesting_app,
              request.remote_ip,
              *Listserv.where(id: listserv_ids)
            )
          end

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
          render json: @market_post, serializer: DetailedMarketPostSerializer,
            context: { current_ability: current_ability }
        end
      end

      private

        def market_post_params
          new_params = params.dup
          attributes = @market_post.present? ? additional_update_attributes : additional_create_attributes
          new_params[:market_post].merge!(attributes)

          new_params.delete(:ugc_base_location_id)

          if new_params[:market_post][:content_locations].present?
            new_params[:market_post][:content_attributes][:content_locations_attributes] = new_params[:market_post].delete(:content_locations).tap do |h|
              h.each do |content_location|
                content_location[:location_id] = Location.find_by(slug: content_location[:location_id]).try(:id)
              end
            end
          end

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
              :promote_radius,
              :ugc_job,
              location_ids: [],
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
              content_category_id: ContentCategory.find_or_create_by(name: 'market').id,
              pubdate: Time.zone.now,
              timestamp: Time.zone.now,
              organization_id: params[:market_post][:organization_id] || Organization.find_or_create_by(name: 'From DailyUV').id,
              ugc_job: params[:market_post][:ugc_job]
            }
          }
        end

        def additional_update_attributes
          additional_attributes = {
            cost: params[:market_post][:price],
            content_attributes: {
              id: params[:id],
              title: params[:market_post][:title],
              raw_content: params[:market_post][:content],
              promote_radius: params[:market_post].delete(:promote_radius)
            }
          }

          additional_attributes
        end

        def location_params
          params[:market_post].slice(:promote_radius, :ugc_base_location_id)
        end

        def set_modifier_for_category(modifier)
          case modifier
            when "OR"
              { operator: "or" }
            when "Match Phrase"
              { match: :phrase }
            else
              {}
          end
        end

        def formatted_query(query)
          unless params[:query_modifier] == "Match Phrase"
            query.split(/[,\s]+/).join(" ")
          else
            query
          end
        end

        def update_locations post
          if location_params[:promote_radius].present? &&
              location_params[:ugc_base_location_id].present?

            UpdateContentLocations.call post.content,
              promote_radius: location_params[:promote_radius].to_i,
              base_locations: [Location.find_by_slug_or_id(location_params[:ugc_base_location_id])]
          end
        end
    end
  end
end
