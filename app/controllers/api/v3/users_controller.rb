module Api
  module V3
    class UsersController < ApiController

      def get_current_user
        if user_signed_in?
          render json: {
            current_user: {
              id: current_user.id,
              name: current_user.name,
              email: current_user.email,
              created_at: current_user.created_at,
              location: Location.find(current_user.location_id).name,
              #TODO: add listserv_id and listserv (need to add associations)
              # listserv_id: Listserv.find(current_user.location_id).id,
              # listserv_name: Listserv.find(current_user.location_id).name,
              test_group: current_user.test_group
            }
          }
        else
          render json: { errors: 'User not logged in' }, status: 404
        end
      end

    end
  end
end
