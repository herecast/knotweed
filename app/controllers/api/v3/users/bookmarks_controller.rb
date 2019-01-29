# frozen_string_literal: true

module Api
  module V3
    class Users::BookmarksController < ApiController
      before_action :check_logged_in!

      def index
        authorize! :manage, UserBookmark
        render json: current_user.user_bookmarks
      end

      def create
        authorize! :create, UserBookmark
        bookmark = current_user.user_bookmarks.build(bookmark_params)
        if bookmark.save
          render json: { bookmark: bookmark }, status: :created
        else
          render json: {}, status: :bad_request
        end
      end

      def update
        bookmark = UserBookmark.find(params[:id])
        authorize! :update, bookmark
        if bookmark.update(bookmark_params)
          render json: { bookmark: bookmark }, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        bookmark = UserBookmark.find(params[:id])
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
    end
  end
end
