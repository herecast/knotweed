module Api
  module V3
    class UsersController < ApiController

      def show
        if @current_api_user.present? 
          listserv = @current_api_user.location.listserv
          listserv_id = listserv ? listserv.id : ""
          render json: {
            current_user: {
              id: @current_api_user.id,
              name: @current_api_user.name,
              email: @current_api_user.email,
              created_at: @current_api_user.created_at,
              location: @current_api_user.location.name,
              listserv_id: listserv_id,
              listserv_name: listserv.name,
              test_group: @current_api_user.test_group.to_s,
              user_image_url: "TODO"
            }
          }, status: 200
        else
          render json: { errors: 'User not logged in' }, status: 401
        end
      end

      def update
        if @current_api_user.present?

        else
          render json: { errors: 'User not logged in' }, status: 401
        end
      end

    end
  end
end
