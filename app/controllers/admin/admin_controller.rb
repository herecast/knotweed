class Admin::AdminController < ApplicationController
  before_filter :authorize_access!

  private

  def authorize_access!
    authorize! :access, :admin
  end

end
