require 'google/api_client'
require 'oauth2'

class DashboardController < ApplicationController

  def index
    authorize! :access, :dashboard
  end

end
