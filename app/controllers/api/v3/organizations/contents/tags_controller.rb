module Api
  module V3
    class Organizations::Contents::TagsController < ApiController
      before_action :check_logged_in!

      def create
        find_content_and_organization
        authorize! :manage, @organization
        @organization.tagged_contents << @content
        render json: {}, status: :created
      end

      def destroy
        find_content_and_organization
        authorize! :manage, @organization
        @organization.tagged_contents.destroy(@content)
        render json: {}, status: :ok
      end

      private

      def find_content_and_organization
        @organization = Organization.find(params[:organization_id])
        @content = Content.find(params[:content_id])
      end
    end
  end
end
