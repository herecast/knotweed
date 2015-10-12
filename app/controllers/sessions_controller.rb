class SessionsController < Devise::SessionsController
  respond_to :html, :json
  after_filter :track, only: :create

  def create
    super do |user|
      if request.format.json?
        data = {
          token: user.authentication_token,
          email: user.email
        }
        render json: data, status: 201 and return
      end
    end
  end

  private

  def track
    @tracker ||= SubtextTracker.new(Figaro.env.mixpanel_api_token)
    @tracker.track(current_user.try(:id), 'signIn', current_user, Hash.new)
  end

end
