module Api
  module V3
    class UsersController < ApiController
      
      before_filter :check_logged_in!, only: [:show, :update, :logout] 
      def show
        if @current_api_user.present? 
          render json: @current_api_user, serializer: UserSerializer, root: 'current_user',  status: 200
        else
          render json: { errors: 'User not logged in' }, status: 401
        end
      end

      def update

        if @current_api_user.present?
          
          #security check in case the user token is stolen, the user id must be
          #stolen as well
          if params[:current_user][:user_id].to_i != @current_api_user.id
            head :unprocessable_entity and return
          end
          
          @current_api_user.name = 
            params[:current_user][:name] if params[:current_user][:name].present?
          if params[:current_user][:location_id].present?
            location = Location.find(params[:current_user][:location_id])
            @current_api_user.location = location
          end
          @current_api_user.email =  params[:current_user][:email] if params[:current_user][:email].present?
          if params[:current_user][:password].present? && 
            params[:current_user][:password_confirmation].present?
            @current_api_user.password = params[:current_user][:password]
            @current_api_user.password_confirmation =
              params[:current_user][:password_confirmation]
          end

          @current_api_user.avatar = params[:current_user][:image] if params[:current_user][:image].present?

          if @current_api_user.save 
            render json: @current_api_user, serializer: UserSerializer, root: 'current_user', status: 200
          else
            render json: { error: "Current User update failed", messages:  @current_api_user.errors.full_messages }, status: 422
          end
        else
          render json: { errors: 'User not logged in' }, status: 401
        end
      end

      def weather
        ForecastIO.api_key = Figaro.env.forecast_io_api_key
        if @current_api_user.present?
          @location = @current_api_user.location
        else
          @location = Location.find_by_city Location::DEFAULT_LOCATION
        end
        @forecast = Rails.cache.fetch("forecast-#{@location.city}", expires_in: 30.minutes) do
          ForecastIO.forecast(@location.lat, @location.long, params: {exclude: 'minutely,daily,hourly'})
        end

        render 'api/v3/users/forecast', layout: false
      end

      def logout
        sign_out @current_api_user
        @current_api_user.reset_authentication_token
        if @current_api_user.save
           res =  :ok 
        else
           res = :unprocessable_entity
        end
        @current_api_user = nil
        reset_session
        render json: {}, status: res
      end

      def email_confirmation
        user = User.confirm_by_token params[:confirmation_token]
        if user.id.present?
          res = { token: user.authentication_token,
                  email: user.email
                }
        else
          head :not_found and return
        end

        render json: res
      end

    end
  end
end
