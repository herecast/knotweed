# Existing Ids: [45, 93, 49, 116, 118, 114, 48, 50, 85, 89, 83, 87, 108]

# Missing: Brookfield, VT, Rochester, VT, Stockbridge, VT, Williamstown, VT
# Missing info: Tunbridge, VT, Windsor, VT, Croydon, NH, Newport, NH, Orford, NH, Piermont, NH, Springfield, NH, Unity, NH

namespace :locations do

  desc 'Update list of locations with which user may identify'
  task :update => :environment do

    # These are the existing locations to be added
    [45, 93, 49, 116, 118, 114, 48, 50, 85, 89, 83, 87, 108].each do |l|
      Location.find(l).update_attribute(:consumer_active, true)
    end

    # These locations need updating
    # Tunbridge, VT
    Location.find(69).update_attributes(zip: '05077', county: 'Orange', lat: '43.9020959', long: '-72.6245026', consumer_active: true)
    # Windsor, VT
    Location.find(73).update_attributes(zip: '05089', county: 'Windsor', lat: '43.4770065', long: '-72.4882185', consumer_active: true)
    # Croydon, NH
    Location.find(53).update_attributes(zip: '03773', county: 'Sullivan', lat: '43.4438852', long: '-72.2616543', consumer_active: true)
    # Newport, NH
    Location.find(60).update_attributes(zip: '03773', county: 'Sullivan', lat: '43.3656802', long: '-72.2677264', consumer_active: true)
    # Orford, NH
    Location.find(62).update_attributes(zip: '03777', county: 'Grafton', lat: '43.8976444', long: '-72.2085055', consumer_active: true)
    # Piermont, NH
    Location.find(63).update_attributes(zip: '03779', county: 'Grafton', lat: '43.9725631', long: '-72.1081503', consumer_active: true)
    # Springfield, NH
    Location.find(67).update_attributes(zip: '03284', county: 'Sullivan', lat: '43.4950544', long: '-72.1653447', consumer_active: true)
    # Unity, NH
    Location.find(70).update_attributes(zip: '03603', county: 'Sullivan', lat: '43.296258', long: '-72.4007716', consumer_active: true)
    # Sunapee, NH
    Location.find(68).update_attributes(zip: '03782', county: 'Sullivan', lat: '43.3878411', long: '-72.1591205', consumer_active: true)


    # These are new locations
    [
      { zip: '05036', city: 'Brookfield', state: 'VT', county: 'Orange', lat: '44.0277895', long: '-72.6668867' },
      { zip: '05767', city: 'Rochester', state: 'VT', county: 'Windsor', lat: '43.8830109', long: '-72.984062' },
      { zip: '05772', city: 'Stockbridge', state: 'VT', county: 'Windsor', lat: '43.7536322', long: '-72.8110102' },
      { zip: '05679', city: 'Williamstown', state: 'VT', county: 'Orange', lat: '44.1063881', long: '-72.6115454' }
    ].each do |hash|
      hash = hash.merge({ consumer_active: true })
      Location.create!(hash)
    end

  end
end