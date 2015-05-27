# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  zip             :string(255)
#  city            :string(255)
#  state           :string(255)
#  county          :string(255)
#  lat             :string(255)
#  long            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  consumer_active :boolean          default(FALSE)
#

require 'spec_helper'

describe Location do
  pending "add some examples to (or delete) #{__FILE__}"
end
