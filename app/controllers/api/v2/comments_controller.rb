module Api
  module V2
    class CommentsController < ApiController

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

    end
  end
end
