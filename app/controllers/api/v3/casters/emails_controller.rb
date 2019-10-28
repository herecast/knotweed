# frozen_string_literal: true

module Api
  module V3
    class Casters::EmailsController < ApiController

      def show
        if Caster.find_by(email: params[:email])
          render json: {}, status: :ok
        else
          render json: {}, status: :not_found
        end
      end
    end
  end
end