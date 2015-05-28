module Api
  module V2
    class CommentsController < ApiController

      before_filter :check_logged_in!, only: [:create, :moderate] 

      def moderate
        comment = Comment.find(params[:id])
        ModerationMailer.send_moderation_flag_v2(comment.content, params[:flag_type],
                                                 @current_api_user).deliver
        head :no_content
      end

      def index
        if params[:event_instance_id].present?
          ei = EventInstance.find params[:event_instance_id]
          root = ei.event.content
        elsif params[:event_id].present?
          e = Event.find params[:event_id]
          root = e.content
        end

        if root.present?
          @comments = root.children.where(channel_type: 'Comment')
        else
          @comments = []
        end
        render json: @comments, each_serializer: CommentSerializer
      end

      def create
        location_ids = [@current_api_user.try(:location_id)]
        if params[:comment][:parent_comment_id].present?
          parent_id = Comment.find(params[:comment][:parent_comment_id]).content.id
        elsif params[:comment][:event_instance_id].present?
          parent_id = EventInstance.find(params[:comment][:event_instance_id]).event.content.id
        else
          parent_id = nil
        end
        # avoid mass assignment errors
        params[:comment].delete :parent_comment_id
        params[:comment].delete :event_instance_id
        
        # parse out content attributes
        params[:comment][:content_attributes] = {
          title: params[:comment].delete(:title),
          parent_id: parent_id,
          location_ids: location_ids,
          authoremail: @current_api_user.try(:email),
          authors: @current_api_user.try(:name),
          raw_content: params[:comment].delete(:content),
          pubdate: Time.zone.now
        }
        @comment = Comment.new(params[:comment])
        if @comment.save

          if @repository.present?
            @comment.content.publish(Content::DEFAULT_PUBLISH_METHOD, @repository)
          end

          render json: @comment.content, serializer: SingleCommentSerializer,
            status: 201, root: 'comment'
        else
          head :unprocessable_entity
        end
      end

    end
  end
end