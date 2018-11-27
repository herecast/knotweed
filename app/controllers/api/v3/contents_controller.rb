module Api
  module V3
    class ContentsController < ApiController
      before_action :check_logged_in!, except:  [:sitemap_ids, :show, :similar_content]

      # For usage in sitemap generation
      def sitemap_ids
        types=(params[:type] || "news,market,talk").split(/,\s*/).map do |type|
          if type == 'talk'
            'talk_of_the_town'
          else
            type
          end
        end

        content_ids = Content.not_deleted
                      .not_listserv
                      .not_removed
                      .not_comment
                      .where('pubdate <= ?', Time.zone.now)
                      .only_categories(types)
                      .order('pubdate DESC')
                      .limit(50_000)
                      .pluck(:id)

        render json: {content_ids: content_ids}
      end

      def create
        authorize! :create, Content

        begin
          create_process = Content::UGC_PROCESSES['create'].fetch(params[:content][:content_type])
        rescue KeyError
          render json: {error: 'unknown content type'}, status: :unprocessable_entity
          return
        end

        @content = create_process.call(params,
          user_scope: current_user
        )

        if @content.valid?
          promote_to_listservs @content
          rescrape_facebook @content

          render json: @content, serializer: ContentSerializer, status: :created
        else
          render json: @content.errors, status: :unprocessable_entity
        end

      rescue Ugc::ValidationError => e
        render json: {errors: [e.message]}, status: :unprocessable_entity
      end

      def show
        expires_in 1.minutes, public: true

        @content = Content.find(params[:id])
        if @content.is_listserv? && !user_signed_in?
          render json: {}, status: :unauthorized
          return
        end

        if has_pubdate_in_past_or_can_edit?
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

        begin
          update_process = Content::UGC_PROCESSES['update'].fetch(@content.content_type.to_s)
        rescue KeyError
          render json: {error: 'unknown content type'}, status: :unprocessable_entity
          return
        end

        success = update_process.call(@content, params,
          user_scope: current_user
        )

        if success
          promote_to_listservs @content
          rescrape_facebook @content

          render json: @content, serializer: ContentSerializer, status: :ok
        else
          render json: @content.errors, status: :unprocessable_entity
        end

      rescue Ugc::ValidationError => e
        render json: {errors: [e.message]}, status: :unprocessable_entity
      end

      def similar_content
        expires_in 1.minutes, :public => true
        @content = Content.find params[:id]

        @contents = @content.similar_content(4)

        render json: @contents, each_serializer: HashieMashes::ContentSerializer,
          root: 'similar_content'
      end

      def moderate
        content = Content.find(params[:id])
        ModerationMailer.send_moderation_flag_v2(content, params[:flag_type], \
          current_user).deliver_later
        head :no_content
      end

      def metrics
        @content = Content.find(params[:id])
        authorize! :manage, @content
        if params[:start_date].present? && params[:end_date].present?
          render json: @content, serializer: ContentMetricsSerializer,
            context: {start_date: params[:start_date], end_date: params[:end_date]}
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        @content = Content.find params[:id]
        authorize! :destroy, @content

        if @content.pubdate.nil?
          @content.update_attribute(:deleted_at, Time.current)
          render json: {}, status: :no_content
        else
          render json: {}, status: :bad_request
        end
      end

      protected

        def has_pubdate_in_past_or_can_edit?
          return false if @content.deleted_at.present?
          return true if can? :manage, @content
          @content.pubdate.present? && @content.pubdate < Time.current
        end

        def promote_to_listservs content
          listserv_ids = params[:content][:listserv_ids] || []

          if listserv_ids.any?
            # reverse publish to specified listservs
            PromoteContentToListservs.call(
              content,
              request.remote_ip,
              *Listserv.where(id: listserv_ids)
            )
          end
        end

        def rescrape_facebook content
          if content.pubdate.present? && content.pubdate < Time.current
            BackgroundJob.perform_later('FacebookService', 'rescrape_url', content)
          end
        end
    end
  end
end
