# == Schema Information
#
# Table name: parameters
#
#  id         :integer          not null, primary key
#  parser_id  :integer
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Parameter, :type => :model do
  skip "add some examples to (or delete) #{__FILE__}"
end
