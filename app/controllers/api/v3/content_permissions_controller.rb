# frozen_string_literal: true

module Api
  module V3
    class ContentPermissionsController < ApiController
      before_action :check_logged_in!

      def index
        contents_array = []
        if params[:content_ids].present?
          contents = Content.find(params[:content_ids])
          contents.each do |content|
            contents_array << { content_id: content.id, can_edit: can?(:crud, content) }
          end
        end

        render json: contents_array, root: :content_permissions
      end
    end
  end
end
