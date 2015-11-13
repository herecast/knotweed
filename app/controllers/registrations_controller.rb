class RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_filter :set_consumer_app_in_thread

  def create 
    super do |user|
      if request.format.json?
        res = {
          :message => "Thank you! For security purposes, a message with a confirmation link has been sent to your email address. Please check your email and click on the link to activate your account. If the message hasn't appeared in a few minutes, please check your spam folder."
        }
        # temporary solution to support running UX1 and UX2 simultaneously
        # can be removed when we moonlight UX1!
        user.nda_agreed_at = Time.zone.now
        user.agreed_to_nda = true
        user.save
        # mixpanel aliasing
        if request.headers['Mixpanel-Distinct-Id'].present?
          tracker = SubtextTracker.new(Figaro.env.mixpanel_api_token)
          tracker.alias(user.id, request.headers['Mixpanel-Distinct-Id'])
          tracker.people.set(user.id, {
            name: user.name,
            '$email' => user.email
          })
        end
        render json: res, status: 201 and return
      end
    end
  end

  private

     def set_consumer_app_in_thread
       if request.headers['Consumer-App-Uri'].present?
         ConsumerApp.current = ConsumerApp.find_by_uri(request.headers['Consumer-App-Uri'])
       end
     end
end
