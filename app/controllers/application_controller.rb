class ApplicationController < ActionController::Base
  protect_from_forgery

  #normal Devise authentication
  before_filter :authorize_access!, :set_current_thread_user, 
    :set_thread_consumer_app_nil

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  rescue_from ActionController::RoutingError, :with => 
    :render_404

  private

  def authorize_access!
    unless self.class == Devise::SessionsController
      authenticate_user!
      #authorize! :access, :admin
    end
  end

  def render_404(exception = nil)
    if exception
      logger.info "Rendering 404: #{exception.message}"
    end

    render :file => "#{Rails.root}/public/404.html",
      :status => 404, :layout => false
  end

  def set_current_thread_user
    User.current = current_user
  end

  # consumer app should never be set for things accessed
  # via the application controller (since that means we're
  # in the admin app).
  def set_thread_consumer_app_nil
    ConsumerApp.current = nil
  end

end
