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

require 'spec_helper'

describe MarketPost do
  pending "add some examples to (or delete) #{__FILE__}"
end
