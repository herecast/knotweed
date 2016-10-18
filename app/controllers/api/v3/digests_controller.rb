module Api
  module V3
    class DigestsController < ApiController
      def index
        expires_in 1.hours, public: true

        @digests = Listserv.where(display_subscribe: true).where(list_type: 'custom_digest')

        render json: @digests, each_serializer: DigestSerializer
      end
    end
  end
end
