module Api
  module V3
    class DigestsController < ApiController
      def index
        expires_in 1.hours, public: true

        @digests = Listserv.active.custom_digest.where(display_subscribe: true)

        render json: @digests, each_serializer: DigestSerializer, root: 'digests'
      end

      def show
        @digest = Listserv.active.custom_digest.find(params[:id])

        render json: @digest, serializer: DigestSerializer, root: 'digest'
      end
    end
  end
end
