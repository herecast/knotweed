# frozen_string_literal: true

module Api
  module V3
    class ContentsController < ApiController
      before_action :check_logged_in!, except: %i[show index]

      def index
        expires_in 1.minutes, public: true unless is_my_stuff_request?
        render(json: { feed_items: [] }, status: :ok) && return if is_my_stuff_request? && current_user.nil?

        @result_object = GatherFeedRecords.call(
          params: params,
          current_user: current_user
        )

        render json: FeedContentVanillaSerializer.call(
          @result_object[:records]
        ).merge(
          meta: {
            total: @result_object[:total_entries],
            total_pages: total_pages
          }
        )
      end

      def create
        authorize! :create, Content

        begin
          create_process = Content::UGC_PROCESSES['create'].fetch(params[:content][:content_type])
        rescue KeyError
          render json: { error: 'unknown content type' }, status: :unprocessable_entity
          return
        end

        Searchkick.callbacks(false) do
          @content = create_process.call(params, user_scope: current_user)
        end
        @content.reindex(mode: true)

        if @content.valid?
          rescrape_facebook @content

          render json: @content, serializer: ContentSerializer, status: :created
        else
          render json: @content.errors, status: :unprocessable_entity
        end
      rescue Ugc::ValidationError => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      def show
        @content = Content.search_by(id: params[:id], user: current_user)
        if @content.removed == true
          @content = CreateAlternateContent.call(Content.find(params[:id]))
          render json: @content, serializer: ContentSerializer, status: :ok
        elsif has_pubdate_in_past_or_can_edit?
          render json: { content: @content }, status: :ok
        else
          render json: {}, status: :not_found
        end
      end

      def update
        @content = Content.find(params[:id])
        authorize! :update, @content

        begin
          update_process = Content::UGC_PROCESSES['update'].fetch(@content.content_type)
        rescue KeyError
          render json: { error: 'unknown content type' }, status: :unprocessable_entity
          return
        end

        Searchkick.callbacks(false) do
           update_process.call(@content, params, user_scope: current_user)
        end
        @content.reload.reindex(mode: true)

        if @content.valid?
          rescrape_facebook @content

          render json: @content, serializer: ContentSerializer, status: :ok
        else
          render json: @content.errors, status: :unprocessable_entity
        end
      rescue Ugc::ValidationError => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
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
        return true if @content.can_edit

        @content.pubdate.present? && @content.pubdate < Time.current
      end

      def rescrape_facebook(content)
        if should_scrape_on_facebook?(content)
          BackgroundJob.perform_later('FacebookService', 'rescrape_url', content)
        end
      end

      def should_scrape_on_facebook?(content)
        content.pubdate.present? && \
          content.pubdate < Time.current && \
          production_messaging_enabled?
      end

      def is_my_stuff_request?
        %w[me my_stuff mystuff].include?(params[:radius].to_s.downcase)
      end

      def total_pages
        @result_object[:total_entries].present? ? (@result_object[:total_entries] / per_page.to_f).ceil : nil
      end

      def per_page
        params[:per_page] || 20
      end
    end
  end
end
