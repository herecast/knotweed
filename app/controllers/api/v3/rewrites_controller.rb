module Api
  module V3
    class RewritesController < ApiController

      def index
        @rewrite = Rewrite.find_by(source: params[:query])
        if @rewrite
          render json: payload, status: :ok
        else
          render json: {}, status: :ok
        end
      end

      private

        def payload
          {
            rewrite: {
              source: @rewrite.source,
              destination: @rewrite.destination
            }
          }
        end

    end
  end
end