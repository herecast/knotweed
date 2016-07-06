class BusinessProfiles::ClaimsController < ApplicationController

  def create
    business_profile = BusinessProfile.find_by(id: params[:id])

    if business_profile
      content_params = {
        title: business_profile.business_location.name,
        pubdate: DateTime.current,
        channel_type: 'BusinessProfile',
        channel_id: business_profile.id
      }

      organization_params = {
        name: business_profile.business_location.name,
        org_type: 'Business'
      }

      content = Content.create(content_params)
      organization = Organization.find_by(name: business_profile.business_location.name) || Organization.create(organization_params)
      content.update_attribute(:organization_id, organization.id)
      ConsumerApp.all.each { |ca| organization.consumer_apps << ca }
      business_profile.update_attribute(:existence, 1.0)
      flash[:notice] = "#{business_profile.business_location.name} has been claimed"
      redirect_to edit_business_profile_path(id: business_profile.id, anchor: 'managers')
    else
      flash[:warning] = "There was a problem claiming this business"
      redirect_to business_profiles_path
    end
  end
end