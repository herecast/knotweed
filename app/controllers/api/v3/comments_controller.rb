# frozen_string_literal: true

module Api
  module V3
    class CommentsController < ApiController
      before_action :check_logged_in!, only: [:create]

      def index
        root = Content.find params[:content_id]

        if root.present? && root.removed == false
          @comments = root.comments
                          .not_deleted
                          .order(pubdate: :desc)
          render json: @comments, each_serializer: CommentSerializer
        else
          render json: [], status: :ok
        end
      end

      def create
        authorize! :create, Comment
        @comment = Comment.new(comment_params)
        if @comment.save
          CommentAlert.call(@comment)
          render json: @comment,
            serializer: CommentSerializer,
            status: 201,
            root: 'comment'
        else
          render json: {}, status: :unprocessable_entity
        end
      end

      private

      def comment_params
        new_params = params
        new_params[:comment] = new_params[:comment].merge(additional_attributes)
        new_params.require(:comment).permit(
          %i[
            content_id
            raw_content
            pubdate
            location_id
            origin
          ]
        )
      end

      def additional_attributes
        {
          content_id: params[:comment][:parent_id],
          raw_content: ActionView::Base.full_sanitizer.sanitize(params[:comment][:content]),
          pubdate: Time.zone.now,
        }
      end
    end
  end
end
