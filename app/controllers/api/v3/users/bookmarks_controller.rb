module Api
  module V3
    class Users::BookmarksController < ApiController
      before_action :confirm_correct_user

      def index
        render json: @current_user.user_bookmarks
      end

      def create
        bookmark = @current_user.user_bookmarks.build(bookmark_params)
        if bookmark.save
          render json: { bookmark: bookmark }, status: :created
        else
          render json: {}, status: :bad_request
        end
      end

      def update
        bookmark = @current_user.user_bookmarks.find(params[:id])
        if bookmark.update(bookmark_params)
          render json: { bookmark: bookmark }, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      def destroy
        user_bookmark = @current_user.user_bookmarks.find(params[:id])
        if user_bookmark.destroy
          render json: {}, status: :ok
        else
          render json: {}, status: :bad_request
        end
      end

      private

        def confirm_correct_user
          unless @current_user.present? && params[:user_id].to_i == @current_user.id
            render json: {}, status: :forbidden
          end
        end

        def total_pages
          @contents.present? ? (@contents.total_entries/per_page.to_f).ceil : nil
        end

        def per_page
          params[:per_page] || 20
        end

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