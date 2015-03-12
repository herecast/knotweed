class MarketPost < ActiveRecord::Base
  attr_accessible :contact_email, :contact_phone, :contact_url, :cost, :latitude, 
    :locate_address, :locate_include_name, :locate_name, :longitude
end
