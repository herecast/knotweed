class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authorize_access!

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

    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

end
