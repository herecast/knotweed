# frozen_string_literal: true

module Api
  module V3
    class FeaturesController < ApiController
      def index
        expires_in 10.minutes, public: true
        @features = Feature.active
        render json: @features, each_serializer: FeatureSerializer
      end
    end
  end
end
