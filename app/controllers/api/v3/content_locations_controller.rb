module Api
  module V3
    class ContentLocationsController < ApiController
      before_filter :check_logged_in!

      def destroy
        content_location = ContentLocation.find(params[:id])
        authorize! :manage, content_location.content

        content_location.destroy
        render status: 204, json: {}
      end
    end
  end
end
