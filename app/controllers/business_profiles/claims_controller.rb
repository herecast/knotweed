class BusinessProfiles::ClaimsController < ApplicationController

  def create
    business_profile = BusinessProfile.find_by(id: params[:id])

    if business_profile
      content_params = {
        title: business_profile.business_location.name,
        pubdate: DateTime.now,
        channel_type: 'BusinessProfile',
        channel_id: business_profile.id
      }

      organization_params = {
        name: business_profile.business_location.name,
        org_type: 'Business'
      }

      content = Content.create(content_params)
      organization = Organization.create(organization_params)
      content.update_attribute(:organization_id, organization.id)
      flash[:notice] = "#{business_profile.business_location.name} has been claimed"
      redirect_to edit_business_profile_path(id: business_profile.id, anchor: 'managers')
    else
      flash[:warning] = "There was a problem claiming this business"
      redirect_to business_profiles_path
    end
  end
end