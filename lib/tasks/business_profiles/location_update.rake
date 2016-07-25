namespace :business_profiles do

  desc 'Update claimed business profile locations with correct organization'
  task :update_location_orgs => :environment do

    sql = "UPDATE organizations
        INNER JOIN contents ON (contents.organization_id = organizations.id and contents.channel_type = 'BusinessProfile')
        INNER JOIN business_profiles ON contents.channel_id = business_profiles.id
        INNER JOIN business_locations ON business_profiles.business_location_id = business_locations.id
        SET business_locations.organization_id = organizations.id;"
    ActiveRecord::Base.connection.execute(sql)

  end
end