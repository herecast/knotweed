module Api
  module V3
    class DigestsController < ApiController
      def index
        expires_in 1.hours, public: true

        @digests = Listserv.all.select{ |ls| ls.is_managed_list? }

        render json: @digests, each_serializer: DigestSerializer
      end
    end
  end
end
