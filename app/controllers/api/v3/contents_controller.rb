# frozen_string_literal: true

module Api
  module V3
    class ContentsController < ApiController
      before_action :check_logged_in!, except: %i[show similar_content]

      def create
        authorize! :create, Content

        begin
          create_process = Content::UGC_PROCESSES['create'].fetch(params[:content][:content_type])
        rescue KeyError
          render json: { error: 'unknown content type' }, status: :unprocessable_entity
          return
        end

        @content = create_process.call(params,
                                       user_scope: current_user)

        if @content.valid?
          promote_to_listservs @content
          rescrape_facebook @content

          render json: @content, serializer: ContentSerializer, status: :created
        else
          render json: @content.errors, status: :unprocessable_entity
        end
      rescue Ugc::ValidationError => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      def show
        expires_in 1.minutes, public: true

        @content = Content.find(params[:id])
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
          render json: { error: 'unknown content type' }, status: :unprocessable_entity
          return
        end

        success = update_process.call(@content, params,
                                      user_scope: current_user)

        if success
          promote_to_listservs @content
          rescrape_facebook @content

          render json: @content, serializer: ContentSerializer, status: :ok
        else
          render json: @content.errors, status: :unprocessable_entity
        end
      rescue Ugc::ValidationError => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      def metrics
        @content = Content.find(params[:id])
        authorize! :manage, @content
        if params[:start_date].present? && params[:end_date].present?
          render json: @content, serializer: ContentMetricsSerializer,
                 context: { start_date: params[:start_date], end_date: params[:end_date] }
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

      def promote_to_listservs(content)
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

      def rescrape_facebook(content)
        if content.pubdate.present? && content.pubdate < Time.current
          BackgroundJob.perform_later('FacebookService', 'rescrape_url', content)
        end
      end
    end
  end
end
