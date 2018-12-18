# frozen_string_literal: true

module Api
  module V3
    class CommentsController < ApiController
      before_action :check_logged_in!, only: [:create]

      # @param the parent content id
      # @return all child comments
      def index
        root = Content.find params[:content_id]
        @comments = []

        if root.present? && root.removed != true
          result_list = if root.content_category.name.in? %w[talk_of_the_town discussion]
                          root.talk_comments
                        else
                          root.comments
                        end
          @comments << result_list.not_deleted
          get_all_comments result_list.not_deleted
          @comments.flatten!
          @comments.sort! { |a, b| b.pubdate <=> a.pubdate }
        end
        render json: @comments, each_serializer: CommentSerializer
      end

      def create
        authorize! :create, Comment
        @comment = Comment.new(comment_params)
        @comment.content.origin = Content::UGC_ORIGIN
        if @comment.save

          CommentAlert.call(@comment)

          render json: @comment.content, serializer: SingleCommentSerializer,
                 status: 201, root: 'comment'
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
            title
            parent_id
            authoremail
            authors
            raw_content
            pubdate
            organization_id
            content_category_id
            location_id
          ]
        )
      end

      def additional_attributes
        {
          content_attributes: {
            title: params[:comment][:title],
            parent_id: params[:comment][:parent_content_id],
            authoremail: current_user.try(:email),
            authors: current_user.try(:name),
            raw_content: ActionView::Base.full_sanitizer.sanitize(params[:comment][:content]),
            pubdate: Time.zone.now,
            organization_id: params[:comment][:organization_id] || Organization.find_or_create_by(name: 'From DailyUV').id,
            content_category_id: ContentCategory.find_or_create_by(name: 'talk_of_the_town').id
          }
        }
      end

      # populates @comments with all nested child comments in the tree
      def get_all_comments(result_list)
        result_list.each do |comment|
          @comments << comment.children if comment.children.present?
          get_all_comments comment.children
        end
      end
    end
  end
end
