module Api
  module V3
    class TalkController < ApiController

      before_filter :check_logged_in!, only: [:create, :update]

      def index
        expires_in 1.minutes, public: true
        opts = { where: {} }
        opts[:page] = params[:page] || 1
        opts[:per_page] = params[:per_page] || 14
        opts[:where][:published] = 1 if @repository.present?
        if @requesting_app.present?
          allowed_orgs = @requesting_app.organizations
          opts[:where][:organization_id] = allowed_orgs.collect{|c| c.id}
        end

        opts[:where][:all_loc_ids] = [Location::REGION_LOCATION_ID]
        opts[:where][:all_loc_ids] << @current_api_user.location_id if @current_api_user


        @talk = Content.talk_search(params[:query], opts)

        render json: @talk[:results], each_serializer: TalkSerializer, meta: { total: @talk[:total] }
      end

      def show
        @talk = Content.find params[:id]
        if @requesting_app.present?
          head :no_content and return unless @requesting_app.organizations.include?(@talk.organization)
        end

        if @talk.try(:root_content_category).try(:name) != 'talk_of_the_town'
          head :no_content and return
        end

        unless @talk.location_ids.include? Location::REGION_LOCATION_ID
          unless @current_api_user
            render_401 and return
          end
        end

        @talk.increment_view_count! unless analytics_blocked?

        if @current_api_user.present? and @repository.present?
          BackgroundJob.perform_later_if_redis_available('DspService', 'record_user_visit', @talk,
                                                         @current_api_user, @repository)
        end

        render json: @talk, serializer: DetailedTalkSerializer, root: 'talk'
      end

      def create
        @talk = Comment.new(talk_params)
        if @talk.save
          listserv_id = params[:talk][:listserv_id]
          if listserv_id.present?
            listserv = Listserv.find(listserv_id)
            PromoteContentToListservs.call(
              @talk.content,
              @requesting_app,
              request.remote_ip,
              listserv
            )
          end

          if @repository.present?
            PublishContentJob.perform_later(@talk.content, @repository, Content::DEFAULT_PUBLISH_METHOD)
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
          head :unprocessable_entity
        end
      end

      private

        def talk_params
          new_params = params
          new_params[:talk].merge!(additional_attributes)
          new_params.require(:talk).permit(
            content_attributes: [
              :title,
              :authoremail,
              :authors,
              :raw_content,
              :pubdate,
              :organization_id,
              :content_category_id,
              location_ids: []
            ]
          )
        end

        def additional_attributes
          {
            content_attributes: {
              title: params[:talk][:title],
              location_ids: [@current_api_user.location_id],
              authoremail: @current_api_user.try(:email),
              authors: @current_api_user.try(:name),
              raw_content: params[:talk][:content],
              pubdate: Time.zone.now,
              organization_id: params[:talk][:organization_id] || Organization.find_or_create_by(name: 'DailyUV').id,
              content_category_id: ContentCategory.find_or_create_by(name: 'talk_of_the_town').id
            }
          }
        end

    end
  end
end
