module Api
  module V2
    class ListservsController < ApiController

      def index
        @listservs = Listserv.all
        render json: @listservs
      end

    end
  end
end
