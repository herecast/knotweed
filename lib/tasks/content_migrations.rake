namespace :content_migrations do
  desc 'Apply single content locations'
  task single_location: :environment do
    default_location = Location.find_by_slug('hartford-vt')

    Content.find_each do |content|
      if content.base_locations.count > 0
        content.location = content.base_locations[0]
      elsif content.about_locations.count > 0
        content.location = content.about_locations[0]
      else
        content.location = default_location
      end
      content.save
      puts "Updated location for #{content.id}"
    end
  end

  desc 'Add radius arrays to Locations'
  task add_radius_arrays_to_locations: :environment do
    Location.consumer_active.each do |location|
      ids = Location.within_radius_of(location.coordinates, 50).map(&:id)
      location.update_attribute(:location_ids_within_fifty_miles, ids)
    end

    Location.consumer_active.each do |location|
      ids = Location.within_radius_of(location.coordinates, 5).map(&:id)
      location.update_attribute(:location_ids_within_five_miles, ids)
    end
  end
end