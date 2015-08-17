module Api
  module V2
    class ListservsController < ApiController

      def index
        @listservs = Listserv.all
        render json: @listservs, arrayserializer: ListservSerializer
      end

    end
  end
end
