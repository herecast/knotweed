# frozen_string_literal: true

module Api
  module V3
    class CastersController < ApiController

      def index
        opts = { page: page, per_page: per_page }
        casters = Caster.search(params[:query], opts)
        render json: casters, each_serializer: CasterSerializer, status: :ok
      end

      def show
        @caster = Caster.find_by(id: params[:id])
        search_by_handle if @caster.nil?
        render json: @caster, serializer: CasterSerializer, status: 200
      end

      private

        def page
          params[:page].present? ? params[:page].to_i : 1
        end

        def per_page
          params[:per_page].present? ? params[:per_page].to_i : 25
        end

        def search_by_handle
          @caster = Caster.where('lower(handle) = ?', params[:handle]&.downcase).first
        end

    end
  end
end