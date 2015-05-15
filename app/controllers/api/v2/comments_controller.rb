module Api
  module V2
    class CommentsController < ApiController

      def index
        if params[:event_instance_id].present?
          ei = EventInstance.find params[:event_instance_id]
          root = ei.event.content
          event_id = ei.event_id
        elsif params[:event_id].present?
          e = Event.find params[:event_id]
          event_id = e.id
          root = e.content
        else
          event_id = nil
        end

        if root.present?
          @comments = root.children.where(channel_type: 'Comment')
        else
          @comments = []
        end
        render json: @comments, each_serializer: CommentSerializer, event_id: event_id
      end

    end
  end
end
