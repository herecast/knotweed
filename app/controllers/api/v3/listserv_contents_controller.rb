module Api
  module V3
    class ListservContentsController < ApiController
      before_action :find_record, only: [:show, :update, :update_metric]

      def show
        render json: @listserv_content, serializer: ListservContentSerializer
      end

      def update
        if VerifyAndUpdateListservContent.call(resource, resource_params)
          render json: resource, serializer: ListservContentSerializer
        else
          render json: resource.errors, status: 422
        end
      rescue ContentOwnerMismatch
        render json: {errors: "Content owner mismatch"}, status: 422
      rescue ListservExceptions::AlreadyVerified
        render status: 422, json: {errors: "Already verified!" }
      end

      def update_metric
        RecordListservMetric.call('update_metric', @listserv_content,
          params.slice(:enhance_link_clicked, :post_type, :step_reached)
        )
        render json: {}, status: :ok
      end

      protected
      def resource
        @listserv_content
      end

      def find_record
        @listserv_content = ListservContent.find_by(key: params[:id])
        head :not_found unless @listserv_content
      end

      def resource_params
        params.require(:listserv_content).permit(
          :subject, :body, :content_id, :channel_type,
          :sender_name
        ).merge(verify_ip: request.remote_ip)
      end
    end
  end
end
