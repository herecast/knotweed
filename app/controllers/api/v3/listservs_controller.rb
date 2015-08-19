module Api
  module V3
    class ListservsController < ApiController

      def index
        @listservs = Listserv.all
        render json: @listservs, arrayserializer: ListservSerializer
      end

    end
  end
end
