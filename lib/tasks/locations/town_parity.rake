namespace :locations do

  def wiki_base_url
    "https://en.wikipedia.org"
  end

  def get_file(link)
    begin
      ext = link.split('.')[-1]
      filename = "/tmp/#{SecureRandom.urlsafe_base64(6)}.#{ext}"
      File.open(filename, "wb") do |f|
        f.write HTTParty.get(link).body
      end
      filename
    rescue
      raise "Issue with image link"
    end
  end

  def coordinates(infobox)
    begin
      coords_link = infobox.css('a.external')[0].attr('href')
      raw_coords_doc = HTTParty.get("https:#{coords_link}")
      coords_doc = Nokogiri::HTML(raw_coords_doc)
      {
        lat: coords_doc.css('span.latitude')[0].inner_text.strip,
        lng: coords_doc.css('span.longitude')[0].inner_text.strip
      }
    rescue
      raise "No coordinates for this town"
    end
  end

  def get_image_link(infobox)
    begin
      raw_image_link = infobox.css('img')[0]
                              .attr('srcset')
                              .split(' ')[-2]
                              .sub('/500', '/1000')
      "https:#{raw_image_link}"
    rescue
      nil
    end
  end

  def add_nearby_locations(locations)
    locations.each do |location|
      if location.location_ids_within_fifty_miles.empty?
        begin
          ids = Location.within_radius_of(location.coordinates, 50).map(&:id)
          location.update_attribute(:location_ids_within_fifty_miles, ids)
          puts "Added nearby location ids for: #{location.pretty_name}"
        rescue Exception => e
          puts "Issue adding nearby locations for: #{location.pretty_name}"
        end
      end
    end
  end

  def build_or_update_location(location_object:, state:)
    location = Location.find_by(city: location_object[:city], state: state)
    begin
      if location
        if location.image.present?
          puts "No updates for: #{location.pretty_name}"
        else
          raw_city_doc = HTTParty.get(location_object[:city_link])
          city_doc = Nokogiri::HTML(raw_city_doc)
          infobox = city_doc.css('table.infobox')
          image_link = get_image_link(infobox)

          if image_link
            location.update_attribute(:image, File.open(get_file(image_link)))
            puts "Added image for: #{location.pretty_name}"
          end
        end
      else
        raw_city_doc = HTTParty.get(location_object[:city_link])
        city_doc = Nokogiri::HTML(raw_city_doc)
        infobox = city_doc.css('table.infobox')
        coords = coordinates(infobox)
        image_link = get_image_link(infobox)

        location = Location.new(
          city: location_object[:city],
          state: state,
          county: location_object[:county],
          consumer_active: true,
          longitude: coords[:lng],
          latitude: coords[:lat]
        )
        location.image = File.open(get_file(image_link)) if image_link
        location.build_slug
        location.save
        puts "New location: #{location.pretty_name}"
      end
    rescue Exception => e
      puts "Issue with #{location_object[:city]}: #{e.inspect}"
    end
  end


  desc 'Vermont municipalities parity'
  task vt_municipalities_parity: :environment do
    town_url = "https://en.wikipedia.org/wiki/List_of_towns_in_Vermont"
    city_url = "https://en.wikipedia.org/wiki/List_of_cities_in_Vermont"
    state = "VT"

    puts "Scraping towns in #{state}"

    location_objects = []

    raw_towns_doc = HTTParty.get(town_url)
    towns_doc = Nokogiri::HTML(raw_towns_doc)
    towns_rows = towns_doc.css('.sortable.wikitable tr')
    towns_rows[1..-1].each do |town_row|
      location_objects << {
        city: town_row.css('td')[1].inner_text.strip,
        county: town_row.css('td')[2].inner_text.strip,
        city_link: "#{wiki_base_url}#{town_row.css('td')[1].css('a')[0].attr('href')}"
      }
    end

    raw_cities_doc = HTTParty.get(city_url)
    cities_doc = Nokogiri::HTML(raw_cities_doc)
    cities_rows = cities_doc.css('.sortable.wikitable tr')
    cities_rows[1..-1].each do |city_row|
      city_link_object = city_row.css('td')[0].css('a')[0]
      location_objects << {
        city: city_link_object.inner_text.strip,
        county: city_row.css('td')[1].inner_text.strip,
        city_link: "#{wiki_base_url}#{city_link_object.attr('href')}"
      }
    end

    location_objects.each do |location_object|
      build_or_update_location(
        location_object: location_object,
        state: state
      )
    end

    add_nearby_locations(Location.where(state: state))
  end


  desc 'New Hampshire municipalities parity'
  task nh_municipalities_parity: :environment do
    url = "https://en.wikipedia.org/wiki/List_of_cities_and_towns_in_New_Hampshire"
    state = "NH"

    puts "Scraping towns in #{state}"

    location_objects = []

    raw_doc = HTTParty.get(url)
    doc = Nokogiri::HTML(raw_doc)
    rows = doc.css('.sortable.wikitable tr')
    rows[1..-1].each do |row|
      location_objects << {
        city: row.css('td')[0].inner_text.strip,
        county: row.css('td')[1].inner_text.strip,
        city_link: "#{wiki_base_url}#{row.css('td')[0].css('a').attr('href')}"
      }
    end

    location_objects.each do |location_object|
      build_or_update_location(
        location_object: location_object,
        state: state
      )
    end

    add_nearby_locations(Location.where(state: state))
  end
end