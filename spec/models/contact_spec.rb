# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  phone        :string(255)
#  email        :string(255)
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  contact_type :string(255)
#  address      :text
#

require 'spec_helper'

describe Contact, :type => :model do
  skip "add some examples to (or delete) #{__FILE__}"
end
