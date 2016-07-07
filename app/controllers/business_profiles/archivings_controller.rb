class BusinessProfiles::ArchivingsController < ApplicationController
  before_action :prevent_deletion_of_published_content, only: [:create]

  def create
    if @business_profile.update_attributes(business_profile_params)
      unclaim_business
      flash[:notice] = "#{@business_profile.business_location.name} has been archived"
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

    def prevent_deletion_of_published_content
      @business_profile = BusinessProfile.find_by(id: params[:id])
      if @business_profile.content.published?
        flash[:warning] = "Cannot delete business with published content"
        redirect_to business_profiles_path
      end
    end

    def unclaim_business
      if @business_profile.claimed?
        @business_profile.organization.destroy
        @business_profile.content.destroy
      end
    end

end