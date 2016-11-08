module Api
  module V3
    class FeaturesController < ApiController
      def index
        @features = Feature.active
        render json: @features, each_serializer: FeatureSerializer
      end
    end
  end
end
