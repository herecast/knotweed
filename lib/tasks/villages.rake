require 'rake'
require 'csv'

namespace :villages do

  desc 'Import from town/village relationships from csv file'
  task import: :environment do
    source_path = File.join(File.dirname(__FILE__),'town_villages.csv')

    last_city = ''
    loc_city = nil

    CSV.foreach(source_path, {:headers => true, :header_converters => :symbol, :converters => :all}) do |row|
      if row[:city] != last_city
        puts "Town of #{row[:city]}, #{row[:state]}"
        loc_city = Location.find_by_city_and_state(row[:city], row[:state])
        if loc_city.nil?
          loc_city = Location.new({city: row[:city], state: row[:state]})
          sleep 1
          coords = Geocoder.coordinates(row[:city] + ',' + row[:state])
          loc_city.lat = coords[0]
          loc_city.long = coords[1]
          loc_city.zip = row[:zip]
          if loc_city.save
            puts "+ #{row[:city]}"
          end
        end
        last_city = row[:city]
      end
      puts "  Village of #{row[:village]}"
      vr = Location.find_by_city_and_state(row[:village], row[:state])
      if vr.nil?
        vr = Location.new({city: row[:village], state: row[:state]})
        sleep 1
        coords = Geocoder.coordinates(row[:village] + ',' + row[:state])
        vr.lat = coords[0]
        vr.long = coords[1]
        vr.parents = [loc_city]
        vr.zip = row[:zip]
        if vr.save
          puts "    + #{row[:village]}"
        end
      end # end of vr.nil?

    end # end of CSV.foreach

  end

=begin
  # Obsolete, read from csv file in import task

  desc "Import Hartford villages into location table"
  task hartford: :environment do
    quechee = {city: 'Quechee', state: 'VT', zip: '05059'}
    wrj = {city: 'White River Junction', state: 'VT', zip: '05001'}
    westhartford = {city: 'West Hartford', state: 'VT', zip: '05001'}
    wilder = {city: 'Wilder', state: 'VT', zip: '05001'}

    village_list = [quechee, wrj, westhartford, wilder]

    hartford = Location.find_by_city_and_state('Hartford', 'VT')
    village_list.each do |village|
      vr = Location.new(village)
      coords = Geocoder.coordinates(village[:city] + ',' +village[:state])
      vr.lat = coords[0]
      vr.long = coords[1]
      vr.parents = [hartford]
      vr.save
    end

  end

  desc "Import Hanover villages into location table"
  task hanover: :environment do
    hancen = {city: 'Hanover Center', state: 'NH', zip: '03755'}
    etna = {city: 'Etna', state: 'NH', zip: '03750'}

    village_list = [hancen, etna]

    town = Location.find_by_city_and_state('Hanover', 'NH')
    village_list.each do |village|
      vr = Location.new(village)
      coords = Geocoder.coordinates(village[:city] + ',' +village[:state])
      vr.lat = coords[0]
      vr.long = coords[1]
      vr.parents = [town]
      vr.save
    end

  end

  desc "Import Lebanon villages into location table"
  task lebanon: :environment do
    wleb = {city: 'West Lebanon', state: 'NH', zip: '03784'}

    village_list = [wleb]

    town = Location.find_by_city_and_state('Lebanon', 'NH')
    village_list.each do |village|
      vr = Location.new(village)
      coords = Geocoder.coordinates(village[:city] + ',' +village[:state])
      vr.lat = coords[0]
      vr.long = coords[1]
      vr.parents = [town]
      vr.save
    end

  end

=end

end
