class Admin::AdminController < ApplicationController
  before_filter :authorize_access!

  layout "admin"

  private

  def authorize_access!
    authorize! :access, :admin
  end

end
