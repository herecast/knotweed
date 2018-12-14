# frozen_string_literal: true

module Api
  module V3
    class ListservsController < ApiController
      def index
        expires_in 1.hours, public: true

        @listservs = if params[:ids].present?
                       Listserv.where(id: params[:ids])
                     else
                       Listserv.active.where.not(list_type: 'custom_digest')
                     end

        render json: @listservs, arrayserializer: ListservSerializer
      end

      def show
        @listserv = Listserv.find(params[:id])
        render json: @listserv, serializer: ListservSerializer
      end
    end
  end
end
