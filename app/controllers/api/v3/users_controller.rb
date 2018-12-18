# frozen_string_literal: true

require 'icalendar/tzinfo'
module Api
  module V3
    class UsersController < ApiController
      include EmailTemplateHelper
      before_action :check_logged_in!, only: %i[show update logout]

      def show
        events_ical_url = url_for_consumer_app('/' + user_event_instances_ics_path(public_id: current_user.public_id.to_s))
        render json: current_user, serializer: UserSerializer,
               root: 'current_user', status: 200, events_ical_url: events_ical_url,
               context: { current_ability: current_ability }
      end

      def update
        authorize! :update, current_user
        if current_user.update_attributes(current_user_params)
          render json: current_user, serializer: UserSerializer, root: 'current_user', status: 200,
                 context: { current_ability: current_ability }
        else
          render json: { error: 'Current User update failed', messages: current_user.errors.full_messages }, status: 422
        end
      end

      def logout
        user = current_user
        sign_out current_user
        user.reset_authentication_token
        res = if user.save
                :ok
              else
                :unprocessable_entity
              end
        reset_session
        render json: {}, status: res
      end

      def email_confirmation
        user = ConfirmRegistration.call(confirmation_token: params[:confirmation_token],
                                        confirm_ip: request.remote_ip)
        if user.errors.blank?
          resp = { token: user.authentication_token,
                   email: user.email }
          render json: resp
        else
          head :not_found
        end
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
          tzid = Time.zone.tzinfo.name
          tz = TZInfo::Timezone.get tzid
          schedules = Schedule.joins(event: :content).where('contents.created_by_id = ?', user.id)
          if schedules.present?
            cal.add_timezone tz.ical_timezone schedules.first.schedule.start_time.to_datetime
          end
          schedules.each do |schedule|
            cal.add_event schedule.to_icalendar_event
          end
          render plain: cal.to_ical
        else
          head :not_found
        end
      end

      def verify
        user = User.where(email: params[:email])
        if user.present?
          render(json: {}, status: :ok) && return
        else
          render(json: {}, status: :not_found) && return
        end
      end

      def email_signin_link(user = User.find_by(email: params[:email]))
        if user.present?
          NotificationService.sign_in_link(
            SignInToken.create(user: user)
          )

          render json: {}, status: :created
        else
          render json: { error: 'email does not match an existing user' }, status: 422
        end
      end

      private

      def current_user_params
        params.require(:current_user).permit(
          :name,
          :email,
          :public_id,
          :location_confirmed,
          :password,
          :password_confirmation,
          :has_had_bookmarks
        ).tap do |attrs|
          if params[:current_user][:location_id].present?
            location = Location.find_by_slug_or_id(params[:current_user][:location_id])
            attrs[:location_id] = location.id
          end
          attrs[:avatar] = params[:current_user][:image] if params[:current_user][:image].present?
        end
      end
    end
  end
end
