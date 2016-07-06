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

      content = Content.find_by(channel_id: business_profile.id, channel_type: 'BusinessProfile') || Content.create(content_params)
      organization = content.organization || Organization.find_or_create_by(name: business_profile.business_location.name)
      organization.update_attribute(:org_type, 'Business') if organization.org_type.nil?
      business_profile.content.update_attribute(:organization_id, organization.id)
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