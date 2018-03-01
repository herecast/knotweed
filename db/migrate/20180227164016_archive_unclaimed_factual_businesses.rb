class ArchiveUnclaimedFactualBusinesses < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute("UPDATE business_profiles SET archived=TRUE WHERE id IN (SELECT business_profiles.id FROM business_profiles INNER JOIN business_locations ON business_location_id=business_locations.id WHERE business_profiles.source='Factual' AND business_profiles.archived=FALSE AND business_locations.organization_id IS NULL)")
  end

  def down
  end
end
