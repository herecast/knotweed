# frozen_string_literal: true

module Api
  module V3
    class Casters::BookmarksController < ApiController
      before_action :check_logged_in!

      def index
        authorize! :manage, CasterBookmark
        caster = Caster.find(params[:caster_id])
        render json: caster.caster_bookmarks
      end

      def create
        authorize! :create, CasterBookmark
        caster = Caster.find(params[:caster_id])
        @bookmark = caster.user_bookmarks.build(bookmark_params)
        if @bookmark.save
          minimal_content_reindex
          render json: { bookmark: @bookmark }, status: :created
        else
          render json: {}, status: :bad_request
        end
      end

      def update
        @bookmark = CasterBookmark.find(params[:id])
        authorize! :update, @bookmark
        if @bookmark.update(bookmark_params)
          minimal_content_reindex
          render json: { bookmark: @bookmark }, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        bookmark = CasterBookmark.find(params[:id])
        authorize! :destroy, bookmark
        if bookmark.destroy
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

      def bookmark_params
        params.require(:bookmark).permit(
          :content_id,
          :event_instance_id,
          :read
        )
      end

      def minimal_content_reindex
        @bookmark.content.reindex(:like_count_data)
      end
    end
  end
end
