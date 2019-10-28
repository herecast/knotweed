# frozen_string_literal: true

module Api
  module V3
    class Casters::SitemapIdsController < ApiController

      def index
        handles = Caster.not_archived.pluck(:handle)
        render json: { handles: handles }, status: :ok
      end
    end
  end
end