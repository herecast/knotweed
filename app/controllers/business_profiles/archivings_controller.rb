class BusinessProfiles::ArchivingsController < ApplicationController

  def create
    business_profile = BusinessProfile.find_by(id: params[:id])
    if business_profile.update_attributes(business_profile_params)
      flash[:notice] = "#{business_profile.business_location.name} has been archived"
    else
      flash[:warning] = "The business was not successfully archived"
    end
    redirect_to business_profiles_path
  end

  def destroy
    business_profile = BusinessProfile.find_by(id: params[:id])
    if business_profile.update_attributes(business_profile_params)
      flash[:notice] = "#{business_profile.business_location.name} has been activated"
    else
      flash[:warning] = "The business was not successfully activated"
    end
    redirect_to business_profiles_path
  end

  private

    def business_profile_params
      params.require(:business_profile).permit(:archived)
    end

end