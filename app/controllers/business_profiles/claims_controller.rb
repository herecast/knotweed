class BusinessProfiles::ClaimsController < ApplicationController

  def create
    business_profile = BusinessProfile.find_by(id: params[:id])

    if business_profile
      CreateBusinessProfileRelationship.call({
        business_profile: business_profile,
        org_name: business_profile.business_location.name
      })

      flash[:notice] = "#{business_profile.business_location.name} has been claimed"
      redirect_to edit_business_profile_path(id: business_profile.id, anchor: 'managers')
    else
      flash[:warning] = "There was a problem claiming this business"
      redirect_to business_profiles_path
    end
  end
end