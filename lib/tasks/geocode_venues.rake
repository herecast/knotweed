namespace :geocode_venues do


  desc "Set lat/long for non-geocoded venues"
  task geocode: :environment do
    not_coded = BusinessLocation.not_geocoded

    puts "There are #{not_coded.count} uncoded venues."

    not_coded.each do |venue|
      sleep 1
      puts "(#{venue.id}): #{venue.name} #{venue.address} #{venue.city}, #{venue.state} #{venue.zip} "
      begin
        coords = Geocoder.coordinates("#{venue.name} #{venue.address} #{venue.city} #{venue.state} #{venue.zip}")
        venue.latitude = coords[0]
        venue.longitude = coords[1]

        if venue.save
          puts "  geocoded at #{coords.to_s}"
        else
          puts "!!!!! not geocoded"
        end
      rescue
        puts "Geocoder failed"
      end
    end
  end

end
