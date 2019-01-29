# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  # normal Devise authentication
  before_action :authorize_access!, :set_current_thread_user,
                :get_version

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  private

  def authorize_access!
    unless self.class == Devise::SessionsController
      authenticate_user!
      # authorize! :access, :admin
    end
  end

  def set_current_thread_user
    User.current = current_user
  end

  def get_version
    @version ||= `git rev-parse --short HEAD`.chomp
  end
end
