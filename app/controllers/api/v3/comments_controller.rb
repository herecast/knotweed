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
                          .not_removed
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
          render json: @comment.content,
                 serializer: CommentSerializer,
                 root: 'comment',
                 status: 201
        else
          render json: {}, status: :unprocessable_entity
        end
      end

      private

      def comment_params
        new_params = params
        new_params[:comment] = new_params[:comment].merge(additional_attributes)
        new_params.require(:comment).permit(
          content_attributes: %i[
            created_by_id
            parent_id
            raw_content
            pubdate
            content_category
            location_id
            origin
          ]
        )
      end

      def additional_attributes
        {
          content_attributes: {
            created_by_id: current_user.id,
            parent_id: params[:comment][:parent_id],
            raw_content: ActionView::Base.full_sanitizer.sanitize(params[:comment][:content]),
            pubdate: Time.zone.now,
            content_category: 'talk_of_the_town',
            location_id: current_user.location_id,
            origin: Content::UGC_ORIGIN
          }
        }
      end
    end
  end
end
