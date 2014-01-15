class Admin::AdminController < ApplicationController
  before_filter :authorize_access!

  layout "admin"

  def dashboard
  end

  private

  def authorize_access!
    authorize! :access, :admin
  end

end
