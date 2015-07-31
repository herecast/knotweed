namespace :geocode_venues do


  desc "Set lat/long for non-geocoded venues"
  task geocode: :environment do
    not_coded = BusinessLocation.not_geocoded
    puts "There are #{not_coded.count} uncoded venues."

    zero_coded = BusinessLocation.find_all_by_latitude_and_longitude(0,0)
    puts "There are #{zero_coded.count} venues with [0,0] coordinates."

    recode = not_coded + zero_coded

    geocoded = failed = not_saved = 0
    recode.each do |venue|
      sleep 1
      puts "(#{venue.id}): #{venue.name} #{venue.address} #{venue.city}, #{venue.state} #{venue.zip} "
      begin
        coords = Geocoder.coordinates("#{venue.name} #{venue.address} #{venue.city} #{venue.state} #{venue.zip}")
        venue.latitude = coords[0]
        venue.longitude = coords[1]

        if venue.save
          puts "  geocoded at #{coords.to_s}"
          geocoded += 1
        else
          puts "!!!!! not saved"
          not_saved += 1
        end
      rescue
        puts "Geocoder failed"
        failed += 1
      end
    end

    puts "\n\nOf the original #{recode.count} venues, #{geocoded} were coded and saved, #{failed} were not recoded and #{not_saved} failed to save."
  end

end
