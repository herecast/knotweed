class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authorize_access!

  def dashboard
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  private

  def authorize_access!
    unless self.class == Devise::SessionsController
      authenticate_user!
      authorize! :access, :admin
    end
  end

end
