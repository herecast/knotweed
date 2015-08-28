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
              location_id: @current_api_user.location.id,
              location: @current_api_user.location.name,
              listserv_id: listserv_id,
              listserv_name: listserv.name,
              test_group: @current_api_user.test_group || "",
              user_image_url: "" 
            }
          }, status: 200
        else
          render json: { errors: 'User not logged in' }, status: 401
        end
      end

      def update
        if @current_api_user.present?
          
          @current_api_user.name = 
            params[:current_user][:name] if params[:current_user][:name]
          if params[:current_user][:location_id]
            location = Location.find(params[:current_user][:location_id])
            @current_api_user.location = location
          end
          @current_api_user.email =  params[:current_user][:email] if params[:current_user][:email]

          if params[:current_user][:password] && 
            params[:current_user][:password_confirmation]
            @current_api_user.password = params[:current_user][:password]
            @current_api_user.password_confirmation =
              params[:current_user][:password_confirmation]
          end

          if @current_api_user.save 
            render json: {}, status: 200
          else
            render json: { error: "Current User update failed", messages:  @current_api_user.errors.full_messages }, status: 422
          end
        else
          render json: { errors: 'User not logged in' }, status: 401
        end
      end

    end
  end
end
