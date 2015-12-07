module Api
  module V3
    class UsersController < ApiController
      
      before_filter :check_logged_in!, only: [:show, :update, :logout] 
      def show
        if @current_api_user.present? 
          if @requesting_app.present?
            events_ical_url = @requesting_app.uri + user_event_instances_ics_path(@current_api_user.public_id.to_s)
          end
          render json: @current_api_user, serializer: UserSerializer, root: 'current_user',  status: 200, events_ical_url: events_ical_url
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
          @current_api_user.public_id = params[:current_user][:public_id] if params[:current_user][:public_id].present?

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
        if user.errors.blank?
          res = { token: user.authentication_token,
                  email: user.email
                }
        else
          head :not_found and return
        end

        render json: res
      end

      def resend_confirmation
        user = User.find_by_email(params[:user][:email])
        if user.present?
          if user.confirmed?
            render json: { message: 'User already confirmed.' }, status: 200
          else
            user.resend_confirmation_instructions
            render json: { message: "We've sent an email to #{params[:user][:email]} containing a confirmation link" },
              status: 200
          end
        else
          render json: { errors: "#{params[:user][:email]} not found" }, status: 404
        end
      end

      def events 
        user = User.find_by_public_id params[:public_id]
        if user
          cal = Icalendar::Calendar.new
          event_instances = EventInstance.joins(event: :content).where('contents.created_by = ?', user.id)
          event_instances.each do |event_instance|
            # intentionally keeping event_instance#ics_event_attributes as private,
            # so it's not exposed to the instance, but we can still
            # call it via send in special cases like here.
            cal.add_event event_instance.send(:ics_event_attributes)
          end
          render text: cal.to_ical
        else
          head :not_found
        end
      end

    end
  end
end
