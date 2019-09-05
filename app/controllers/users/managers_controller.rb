# frozen_string_literal: true

class Users::ManagersController < ApplicationController
  def create
    get_organization
    user = User.find_by(id: params[:user_id])
    user.add_role :manager, @org
    flash[:alert] = "#{user.email} has been added as manager"
    redirect_to(edit_organization_path(@org, anchor: 'managers'))
  end

  def destroy
    get_organization
    user = User.find_by(id: params[:user_id])
    user.remove_role :manager, @org
    flash[:alert] = "#{user.email} has been removed as manager"
    redirect_to(edit_organization_path(@org, anchor: 'managers'))
  end

  private

  def get_organization
    @org = if params[:organization_id].present?
             Organization.find(params[:organization_id])
           end
  end
end
