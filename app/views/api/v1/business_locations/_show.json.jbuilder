json.venue do
  attrs = [:id, :name, :email, :hours, :phone, :latitude, :longitude, :venue_url, :locate_include_name]
  json.address [venue.address, venue.city, venue.state, venue.zip].join(' ')
  attrs.each{ |attr| json.set! attr, venue.send(attr) }
end
