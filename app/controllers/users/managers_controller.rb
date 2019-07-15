# frozen_string_literal: true

class Users::ManagersController < ApplicationController
  def create
    get_organization
    user = User.find_by(id: params[:user_id])
    user.add_role :manager, @org
    flash[:alert] = "#{user.email} has been added as manager"
    smart_redirect
  end

  def destroy
    get_organization
    user = User.find_by(id: params[:user_id])
    user.remove_role :manager, @org
    flash[:alert] = "#{user.email} has been removed as manager"
    smart_redirect
  end

  private

  def get_organization
    @org = if params[:organization_id].present?
             Organization.find(params[:organization_id])
           else
             BusinessProfile.find(params[:business_profile_id]).content.organization
           end
  end

  def smart_redirect
    if params[:organization_id].present?
      redirect_to(edit_organization_path(@org, anchor: 'managers'))
    else
      redirect_to(edit_business_profile_path(BusinessProfile.find(params[:business_profile_id]), anchor: 'managers'))
    end
  end
end
