module Api
  module V3
    class Contents::SimilarContentsController < ApiController

      def index
        expires_in 1.minutes, public: true
        @content = Content.find(params[:content_id])

        @similar_content = @content.similar_content(4)

        render json: @similar_content,
          each_serializer: HashieMashes::ContentSerializer,
          root: 'similar_content'
      end
    end
  end
end