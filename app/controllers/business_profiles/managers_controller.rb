class BusinessProfiles::ManagersController < ApplicationController

  def create
    business_profile = BusinessProfile.find_by(id: params[:business_profile_id])
    user = User.find_by(id: params[:user_id])
    org = business_profile.content.organization
    user.add_role :manager, org
    flash[:alert] = "#{user.email} has been added as manager"
    redirect_to edit_business_profile_path(business_profile)
  end

  def destroy
    business_profile = BusinessProfile.find_by(id: params[:id])
    user = User.find_by(id: params[:user_id])
    org = business_profile.content.organization
    user.remove_role :manager, org
    flash[:alert] = "#{user.email} has been removed as manager"
    redirect_to edit_business_profile_path(business_profile)
  end
end
