# == Schema Information
#
# Table name: market_posts
#
#  id                  :integer          not null, primary key
#  cost                :string(255)
#  contact_phone       :string(255)
#  contact_email       :string(255)
#  contact_url         :string(255)
#  locate_name         :string(255)
#  locate_address      :string(255)
#  latitude            :float
#  longitude           :float
#  locate_include_name :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class MarketPost < ActiveRecord::Base
  attr_accessible :contact_email, :contact_phone, :contact_url, :cost, :latitude, 
    :locate_address, :locate_include_name, :locate_name, :longitude
end
