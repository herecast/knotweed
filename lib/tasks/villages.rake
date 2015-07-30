require 'rake'

namespace :villages do

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
end
