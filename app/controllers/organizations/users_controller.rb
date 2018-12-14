class Organizations::UsersController < ApplicationController
  authorize_resource

  # this loads the users table for the organizations form
  def index
    @organization = Organization.find(params[:organization_id])
    @managers = User.with_role(:manager, @organization)
    @users = User.all
    render 'index', layout: false
  end
end
