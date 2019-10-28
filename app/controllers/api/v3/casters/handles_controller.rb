# frozen_string_literal: true

module Api
  module V3
    class Casters::HandlesController < ApiController

      def show
        if Caster.find_by(handle: params[:handle])
          render json: {}, status: :ok
        else
          render json: {}, status: :not_found
        end
      end
    end
  end
end