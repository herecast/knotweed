module Api
  module V3
    class TalkController < ApiController
      
      before_filter :check_logged_in!, only: [:index, :show, :create, :update]
      after_filter :track_index, only: :index
      after_filter :track_show, only: :show
      after_filter :track_create, only: :create

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

        location_condition = @current_api_user.location_id

        root_talk_cat = ContentCategory.find_by_name 'talk_of_the_town'

        opts[:with].merge!({
          all_loc_ids: [location_condition], 
          root_content_category_id: root_talk_cat.id
        })

        if params[:query].present?
          query = Riddle::Query.escape(params[:query]) 
        else
          query = ''
        end

        @talk = Content.search query, opts
        render json: @talk, each_serializer: TalkSerializer
      end

      def show
        @talk = Content.find params[:id]
        if @requesting_app.present?
          head :no_content and return unless @requesting_app.try(:publications).try(:include?, @talk.content.publication)
        end

        if @talk.try(:root_content_category).try(:name) != 'talk_of_the_town'
          head :no_content
        else
          @talk.increment_integer_attr!(:view_count)
          render json: @talk, serializer: DetailedTalkSerializer, root: 'talk'
        end
      end

      def create
        # hard coded publication...
        pub = Publication.find_or_create_by_name 'DailyUV'

        # hard code category
        cat = ContentCategory.find_or_create_by_name 'talk_of_the_town'

        listserv_id = params[:talk].delete :listserv_id
        
        # parse out content attributes
        content_attributes = {
          title: params[:talk][:title],
          location_ids: [@current_api_user.location_id],
          authoremail: @current_api_user.try(:email),
          authors: @current_api_user.try(:name),
          raw_content: params[:talk][:content],
          pubdate: Time.zone.now,
          publication_id: pub.id,
          content_category_id: cat.id
        }

        @talk = Comment.new({ content_attributes: content_attributes })

        if @talk.save
          if listserv_id.present?
            list = Listserv.find(listserv_id)
            PromotionListserv.create_from_content(@talk.content, list, @requesting_app) if list.present? and list.active
          end

          if @repository.present?
            @talk.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end

          render json: @talk.content, serializer: TalkSerializer,
            status: 201
        else
          head :unprocessable_entity
        end 
      end

      # NOTE, as of now, this method is ONLY for image uploading
      def update
        @content = Content.find(params[:id])
        image_data = params[:talk].delete :image
        # clear out existing images since we are only set up to have one right now
        @content.images.destroy_all if image_data.present?
        if Image.create(image: image_data, imageable: @content)
          render json: @content, serializer: TalkSerializer, status: 200
        else
          render json: { errors: @content.errors.messages },
            status: :unprocessable_entity
        end
      end

      private

      def track_index
        props = {}
        props.merge! @tracker.navigation_properties('Talk', 'talk.index', url_for, params)
        props.merge! @tracker.search_properties(params)
        @tracker.track(@mixpanel_distinct_id, 'searchContent', @current_api_user, props)
      end

      def track_show
        props = {}
        props.merge! @tracker.navigation_properties('Talk', 'talk.show', url_for, params)
        props.merge! @tracker.content_properties(@talk)
        @tracker.track(@mixpanel_distinct_id, 'selectContent', @current_api_user, props)
      end

      def track_create
        props = {}
        props.merge! @tracker.content_properties(@talk)
        props.merge! @tracker.content_creation_properties('create',nil)
        @tracker.track(@mixpanel_distinct_id, 'submitContent', @current_api_user, props)
      end
    end

  end
end
