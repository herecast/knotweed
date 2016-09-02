module Api
  module V3
    class ListservsController < ApiController

      def index
        expires_in 1.hours, public: true
        @listservs = Listserv.all
        render json: @listservs, arrayserializer: ListservSerializer
      end

    end
  end
end
