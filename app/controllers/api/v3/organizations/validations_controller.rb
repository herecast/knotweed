module Api
  module V3
    class Organizations::ValidationsController < ApiController
      def show
        name = URI.decode(params[:name])
        if Organization.find_by_name(name).present?
          render json: {}, status: :not_acceptable
        else
          render json: {}, status: :ok
        end
      end
    end
  end
end
