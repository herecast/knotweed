# == Schema Information
#
# Table name: datasets
#
#  id              :integer          not null, primary key
#  data_context_id :integer
#  name            :string(255)
#  description     :string(255)
#  realm           :string(255)
#  model_type      :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe Dataset, :type => :model do
  skip "add some examples to (or delete) #{__FILE__}"
end
