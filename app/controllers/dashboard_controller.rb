class DashboardController < ApplicationController
  def index
    authorize! :access, :dashboard
  end
end
