module Api
  module V3
    class TalkController < ApiController

      before_filter :check_logged_in!, only: [:create, :update]

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

        render json: @talk, serializer: DetailedTalkSerializer, root: 'talk'
      end

      def create
        @talk = Comment.new(talk_params)

        if location_params[:promote_radius].present? &&
            location_params[:ugc_base_location_id].present?
          UpdateContentLocations.call @talk.content,
            promote_radius: location_params[:promote_radius].to_i,
            base_locations: [Location.find_by_slug_or_id(location_params[:ugc_base_location_id])]
        end

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
          render json: {errors: @talk.content.errors}, status: :unprocessable_entity
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
          render json: {errors: @talk.content.errors}, status: :unprocessable_entity
        end
      end

      private

        def talk_params
          new_params = ActionController::Parameters.new(
            talk: params[:talk].to_h
          )
          new_params[:talk].merge!(additional_attributes)
          new_params[:talk].delete(:promote_radius)
          new_params[:talk].delete(:ugc_base_location_id)
          new_params.require(:talk).permit(
            content_attributes: [
              :title,
              :authoremail,
              :authors,
              :raw_content,
              :pubdate,
              :organization_id,
              :content_category_id,
              :ugc_job
            ]
          )
        end

        def location_params
          params[:talk].slice(:promote_radius, :ugc_base_location_id)
        end

        def additional_attributes
          {
            content_attributes: {
              title: params[:talk][:title],
              authoremail: @current_api_user.try(:email),
              authors: @current_api_user.try(:name),
              raw_content: params[:talk][:content],
              pubdate: Time.zone.now,
              organization_id: params[:talk][:organization_id] || Organization.find_or_create_by(name: 'From DailyUV').id,
              content_category_id: ContentCategory.find_or_create_by(name: 'talk_of_the_town').id,
              promote_radius: params[:talk][:promote_radius],
              ugc_job: params[:talk][:ugc_job]
            }
          }
        end

    end
  end
end
