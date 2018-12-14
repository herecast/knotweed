# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    authorize! :access, :dashboard
  end
end
