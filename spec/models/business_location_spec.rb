# == Schema Information
#
# Table name: business_locations
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  organization_id :integer
#  address         :string(255)
#  phone           :string(255)
#  email           :string(255)
#  hours           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe BusinessLocation do
  pending "add some examples to (or delete) #{__FILE__}"
end